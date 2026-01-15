variable "gemini_api_key" {
  description = "Gemini API key"
  type        = string
  sensitive   = true
}

variable "gemini_model" {
  description = "Gemini model name to use"
  type        = string
  default     = "gemini-3-flash-preview"
}
