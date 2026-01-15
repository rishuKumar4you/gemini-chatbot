#!/bin/bash
set -e

# Log output to file for debugging
exec > >(tee /var/log/user-data.log) 2>&1
echo "Starting setup at $(date)"

# Update system
dnf update -y

# Install Python 3.11 and Git
dnf install -y python3.11 python3.11-pip git

# Create app directory
mkdir -p /opt/gemini-chatbot
cd /opt/gemini-chatbot

# Clone or download the application
# For now, we'll create the files directly

# Create requirements.txt
cat > requirements.txt << 'EOF'
google-generativeai==0.8.3
gradio==5.9.1
cryptography
python-dotenv
boto3
EOF

# Create config.py
cat > config.py << 'CONFIGEOF'
import os
import json
from dotenv import load_dotenv

load_dotenv()

def get_aws_secret(secret_name, region_name="ap-south-1"):
    try:
        import boto3
        from botocore.exceptions import ClientError, NoCredentialsError
        
        client = boto3.client(service_name="secretsmanager", region_name=region_name)
        response = client.get_secret_value(SecretId=secret_name)
        
        if "SecretString" in response:
            return json.loads(response["SecretString"])
    except Exception as e:
        print(f"Error fetching from AWS Secrets Manager: {e}")
    return None

class Config:
    AWS_SECRET_NAME = os.getenv("AWS_SECRET_NAME", "${secret_name}")
    AWS_REGION = os.getenv("AWS_REGION", "${aws_region}")
    USE_AWS_SECRETS = os.getenv("USE_AWS_SECRETS", "true").lower() == "true"
    _secrets_cache = None
    
    @classmethod
    def _load_secrets(cls):
        if cls._secrets_cache is not None:
            return cls._secrets_cache
        if cls.USE_AWS_SECRETS:
            print("Fetching secrets from AWS Secrets Manager...")
            cls._secrets_cache = get_aws_secret(cls.AWS_SECRET_NAME, cls.AWS_REGION)
            if cls._secrets_cache:
                print("Successfully loaded secrets from AWS")
                return cls._secrets_cache
        cls._secrets_cache = {}
        return cls._secrets_cache
    
    @classmethod
    def get(cls, key, default=None):
        secrets = cls._load_secrets()
        if key in secrets:
            return secrets[key]
        return os.getenv(key, default)
    
    @classmethod
    def get_gemini_api_key(cls):
        return cls.get("GEMINI_API_KEY") or cls.get("TF_VAR_gemini_api_key")
    
    @classmethod
    def get_gemini_model(cls):
        return cls.get("GEMINI_MODEL", "gemini-3-flash-preview")
CONFIGEOF

# Create chatbot.py
cat > chatbot.py << 'CHATBOTEOF'
import google.generativeai as genai
import gradio as gr
from config import Config

API_KEY = Config.get_gemini_api_key()
MODEL_NAME = Config.get_gemini_model()

if not API_KEY:
    print("Warning: GEMINI_API_KEY not set!")

genai.configure(api_key=API_KEY)
print(f"Using model: {MODEL_NAME}")
model = genai.GenerativeModel(MODEL_NAME)

chat_session = None

def respond(message, history):
    global chat_session
    if chat_session is None:
        chat_session = model.start_chat(history=[])
    try:
        response = chat_session.send_message(message)
        return response.text
    except Exception as e:
        return f"Error: {str(e)}"

with gr.Blocks(title="Gemini Chatbot") as demo:
    gr.HTML("<h1>Gemini Chatbot</h1>")
    chatbot = gr.ChatInterface(
        fn=respond,
        type="messages",
        chatbot=gr.Chatbot(height=450, type="messages"),
    )

if __name__ == "__main__":
    print("Starting Gemini Chatbot...")
    demo.launch(server_name="0.0.0.0", server_port=7860)
CHATBOTEOF

# Install Python dependencies
python3.11 -m pip install -r requirements.txt

# Create systemd service
cat > /etc/systemd/system/gemini-chatbot.service << 'EOF'
[Unit]
Description=Gemini Chatbot
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/gemini-chatbot
Environment="USE_AWS_SECRETS=true"
ExecStart=/usr/bin/python3.11 chatbot.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
systemctl daemon-reload
systemctl enable gemini-chatbot
systemctl start gemini-chatbot

echo "Setup complete at $(date)"
