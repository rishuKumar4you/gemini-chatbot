# IAM Instance Profile for EC2
# This allows the EC2 instance (not you) to access Secrets Manager

# Trust policy - allows EC2 service to assume this role
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# IAM Role for the EC2 instance
resource "aws_iam_role" "chatbot_role" {
  name               = "gemini-chatbot-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

# Policy - allow EC2 to read the specific secret
data "aws_iam_policy_document" "secrets_access" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = [aws_secretsmanager_secret.gemini_api.arn]
  }
}

resource "aws_iam_role_policy" "secrets_policy" {
  name   = "secrets-access"
  role   = aws_iam_role.chatbot_role.id
  policy = data.aws_iam_policy_document.secrets_access.json
}

# Instance Profile (attaches role to EC2)
resource "aws_iam_instance_profile" "chatbot_profile" {
  name = "gemini-chatbot-profile"
  role = aws_iam_role.chatbot_role.name
}
