# Logs, alarms and a dashboard for one ECS service behind an ALB.
# Alarms notify an SNS topic; an email subscription is created when
# alarm_email is set (AWS sends a confirmation link first).

data "aws_region" "current" {}

locals {
  region = data.aws_region.current.region

  alb_dims = { LoadBalancer = var.alb_arn_suffix }
  tg_dims  = { LoadBalancer = var.alb_arn_suffix, TargetGroup = var.target_group_arn_suffix }
  svc_dims = { ClusterName = var.cluster_name, ServiceName = var.service_name }

  alarm_actions = [aws_sns_topic.alarms.arn]
}

resource "aws_cloudwatch_log_group" "app" {
  #checkov:skip=CKV_AWS_338:14-day retention is a deliberate cost choice for this service's logs.
  name              = "/ecs/${var.name}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn
}

resource "aws_sns_topic" "alarms" {
  name              = "${var.name}-alarms"
  kms_master_key_id = var.kms_key_arn
}

resource "aws_sns_topic_subscription" "email" {
  count = var.alarm_email == null ? 0 : 1

  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

# ---- alarms -------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "http_5xx" {
  alarm_name          = "${var.name}-http-5xx"
  alarm_description   = "5xx responses (from the ALB or the tasks) above ${var.http_5xx_threshold}/min."
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.http_5xx_threshold
  evaluation_periods  = 5
  datapoints_to_alarm = 3
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions

  metric_query {
    id          = "total"
    expression  = "FILL(elb, 0) + FILL(target, 0)"
    label       = "5xx per minute"
    return_data = true
  }

  metric_query {
    id = "elb"
    metric {
      namespace   = "AWS/ApplicationELB"
      metric_name = "HTTPCode_ELB_5XX_Count"
      dimensions  = local.alb_dims
      period      = 60
      stat        = "Sum"
    }
  }

  metric_query {
    id = "target"
    metric {
      namespace   = "AWS/ApplicationELB"
      metric_name = "HTTPCode_Target_5XX_Count"
      dimensions  = local.alb_dims
      period      = 60
      stat        = "Sum"
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "latency_p95" {
  alarm_name          = "${var.name}-latency-p95"
  alarm_description   = "p95 target response time above ${var.latency_p95_threshold_seconds}s."
  namespace           = "AWS/ApplicationELB"
  metric_name         = "TargetResponseTime"
  dimensions          = local.tg_dims
  extended_statistic  = "p95"
  period              = 60
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.latency_p95_threshold_seconds
  evaluation_periods  = 5
  datapoints_to_alarm = 3
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "cpu" {
  alarm_name          = "${var.name}-cpu-high"
  alarm_description   = "Service average CPU above ${var.cpu_threshold_percent}% (autoscaling should already be reacting)."
  namespace           = "AWS/ECS"
  metric_name         = "CPUUtilization"
  dimensions          = local.svc_dims
  statistic           = "Average"
  period              = 60
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.cpu_threshold_percent
  evaluation_periods  = 5
  datapoints_to_alarm = 5
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "running_tasks" {
  alarm_name          = "${var.name}-running-tasks-low"
  alarm_description   = "Fewer than ${var.min_running_tasks} running tasks."
  namespace           = "ECS/ContainerInsights"
  metric_name         = "RunningTaskCount"
  dimensions          = local.svc_dims
  statistic           = "Minimum"
  period              = 60
  comparison_operator = "LessThanThreshold"
  threshold           = var.min_running_tasks
  evaluation_periods  = 3
  datapoints_to_alarm = 3
  # No data means no tasks reporting at all - that is the failure we want to see.
  treat_missing_data = "breaching"
  alarm_actions      = local.alarm_actions
  ok_actions         = local.alarm_actions
}

# ---- dashboard ----------------------------------------------------------------

resource "aws_cloudwatch_dashboard" "this" {
  dashboard_name = var.name

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric", x = 0, y = 0, width = 12, height = 6
        properties = {
          title  = "Requests and 5xx (per minute)"
          region = local.region
          stat   = "Sum"
          period = 60
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_arn_suffix],
            [".", "HTTPCode_Target_5XX_Count", ".", "."],
            [".", "HTTPCode_ELB_5XX_Count", ".", "."],
          ]
        }
      },
      {
        type = "metric", x = 12, y = 0, width = 12, height = 6
        properties = {
          title  = "Target response time (s)"
          region = local.region
          period = 60
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", var.alb_arn_suffix, "TargetGroup", var.target_group_arn_suffix, { stat = "p50", label = "p50" }],
            ["...", { stat = "p95", label = "p95" }],
            ["...", { stat = "p99", label = "p99" }],
          ]
          annotations = { horizontal = [{ label = "p95 alarm", value = var.latency_p95_threshold_seconds }] }
        }
      },
      {
        type = "metric", x = 0, y = 6, width = 12, height = 6
        properties = {
          title  = "Service CPU and memory (%)"
          region = local.region
          stat   = "Average"
          period = 60
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", var.cluster_name, "ServiceName", var.service_name],
            [".", "MemoryUtilization", ".", ".", ".", "."],
          ]
          yAxis = { left = { min = 0, max = 100 } }
        }
      },
      {
        type = "metric", x = 12, y = 6, width = 12, height = 6
        properties = {
          title  = "Tasks and healthy targets"
          region = local.region
          period = 60
          metrics = [
            ["ECS/ContainerInsights", "RunningTaskCount", "ClusterName", var.cluster_name, "ServiceName", var.service_name, { stat = "Average", label = "running tasks" }],
            [".", "DesiredTaskCount", ".", ".", ".", ".", { stat = "Average", label = "desired tasks" }],
            ["AWS/ApplicationELB", "HealthyHostCount", "LoadBalancer", var.alb_arn_suffix, "TargetGroup", var.target_group_arn_suffix, { stat = "Minimum", label = "healthy targets" }],
          ]
          yAxis = { left = { min = 0 } }
        }
      },
      {
        type = "alarm", x = 0, y = 12, width = 24, height = 3
        properties = {
          title = "Alarms"
          alarms = [
            aws_cloudwatch_metric_alarm.http_5xx.arn,
            aws_cloudwatch_metric_alarm.latency_p95.arn,
            aws_cloudwatch_metric_alarm.cpu.arn,
            aws_cloudwatch_metric_alarm.running_tasks.arn,
          ]
        }
      },
    ]
  })
}
