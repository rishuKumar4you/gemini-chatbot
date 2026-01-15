output "secret_name" {
  description = "Name of the AWS Secrets Manager secret"
  value       = aws_secretsmanager_secret.gemini_api.name
}

output "secret_arn" {
  description = "ARN of the AWS Secrets Manager secret"
  value       = aws_secretsmanager_secret.gemini_api.arn
}

output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.chatbot.id
}

output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.chatbot.public_ip
}

output "chatbot_url" {
  description = "URL to access the chatbot"
  value       = "http://${aws_instance.chatbot.public_ip}:7860"
}
