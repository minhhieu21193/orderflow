output "role_arn" {
  description = "Deploy role ARN; store it as the AWS_DEPLOY_ROLE_ARN GitHub variable."
  value       = aws_iam_role.deploy.arn
}
