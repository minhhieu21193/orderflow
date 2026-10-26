output "address" {
  description = "Hostname of the instance."
  value       = aws_db_instance.this.address
}

output "port" {
  description = "Port of the instance."
  value       = aws_db_instance.this.port
}

output "database_name" {
  description = "Initial database name."
  value       = aws_db_instance.this.db_name
}

output "master_username" {
  description = "Master username."
  value       = aws_db_instance.this.username
}

output "master_user_secret_arn" {
  description = "Secrets Manager secret holding the master credentials (JSON with username/password)."
  value       = aws_db_instance.this.master_user_secret[0].secret_arn
}
