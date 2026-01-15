# Store secrets as JSON object so the application can read multiple values
resource "aws_secretsmanager_secret_version" "gemini_api_value" {
  secret_id = aws_secretsmanager_secret.gemini_api.id
  secret_string = jsonencode({
    GEMINI_API_KEY = var.gemini_api_key
    GEMINI_MODEL   = var.gemini_model
  })
}
