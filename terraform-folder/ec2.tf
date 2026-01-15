# EC2 Instance for Gemini Chatbot
# Using t2.micro (Free Tier eligible)

# Get latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Security Group - Allow SSH and Gradio port
resource "aws_security_group" "chatbot_sg" {
  name        = "gemini-chatbot-sg"
  description = "Security group for Gemini Chatbot"

  # SSH access
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Gradio web interface
  ingress {
    description = "Gradio UI"
    from_port   = 7860
    to_port     = 7860
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "gemini-chatbot-sg"
  }
}

# EC2 Instance
resource "aws_instance" "chatbot" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"  # Free tier in ap-south-1
  key_name               = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.chatbot_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.chatbot_profile.name
  associate_public_ip_address = true

  # Root volume (Free tier: 30GB)
  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  # User data script to set up the application
  user_data = templatefile("${path.module}/user_data.sh", {
    aws_region  = "ap-south-1"
    secret_name = aws_secretsmanager_secret.gemini_api.name
  })

  tags = {
    Name = "gemini-chatbot"
  }
}
