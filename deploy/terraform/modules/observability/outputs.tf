output "log_group_name" {
  description = "Application log group name."
  value       = aws_cloudwatch_log_group.app.name
}

output "alarm_topic_arn" {
  description = "SNS topic that receives alarm notifications."
  value       = aws_sns_topic.alarms.arn
}

output "dashboard_name" {
  description = "CloudWatch dashboard name."
  value       = aws_cloudwatch_dashboard.this.dashboard_name
}
