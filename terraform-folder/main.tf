resource "aws_secretsmanager_secret" "gemini_api" {
  name        = "gemini_api_key"
  description = "API key for Gemini chatbot"
}

