output "secret_name" {
  description = "Name of the AWS Secrets Manager secret"
  value       = aws_secretsmanager_secret.gemini_api.name
}

output "secret_arn" {
  description = "ARN of the AWS Secrets Manager secret"
  value       = aws_secretsmanager_secret.gemini_api.arn
}
