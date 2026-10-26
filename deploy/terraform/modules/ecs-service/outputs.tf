output "cluster_name" {
  description = "ECS cluster name."
  value       = aws_ecs_cluster.this.name
}

output "service_name" {
  description = "ECS service name."
  value       = aws_ecs_service.this.name
}

output "service_arn" {
  description = "ECS service ARN."
  value       = aws_ecs_service.this.id
}

output "task_family" {
  description = "Task definition family."
  value       = aws_ecs_task_definition.this.family
}

output "container_name" {
  description = "Name of the app container in the task definition."
  value       = local.container_name
}

output "execution_role_arn" {
  description = "Task execution role ARN."
  value       = aws_iam_role.execution.arn
}

output "task_role_arn" {
  description = "Task role ARN."
  value       = aws_iam_role.task.arn
}

output "task_security_group_id" {
  description = "Security group of the tasks."
  value       = aws_security_group.tasks.id
}

output "alb_dns_name" {
  description = "Public DNS name of the ALB."
  value       = aws_lb.this.dns_name
}

output "alb_arn_suffix" {
  description = "ALB ARN suffix, for CloudWatch metric dimensions."
  value       = aws_lb.this.arn_suffix
}

output "target_group_arn_suffix" {
  description = "Target group ARN suffix, for CloudWatch metric dimensions."
  value       = aws_lb_target_group.this.arn_suffix
}

output "url" {
  description = "Base URL of the service."
  value       = "${local.https_enabled ? "https" : "http"}://${aws_lb.this.dns_name}"
}
