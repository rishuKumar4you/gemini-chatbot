# Gemini Chatbot

A conversational AI chatbot powered by Google's Gemini models, featuring a modern Gradio web interface.

## About the Application

This chatbot provides a clean, user-friendly interface to interact with Google's Gemini AI models. It supports real-time conversations with memory within each session.

### Key Features

- 💬 Real-time chat with Gemini AI
- 🔄 Conversation memory within session
- 🎨 Modern, responsive UI built with Gradio
- 🔐 Secure secrets management via AWS Secrets Manager
- ⚙️ Configurable model selection

---

## Configuration

The application relies on **two configuration values**:

| Variable | Description | Example |
|----------|-------------|---------|
| `GEMINI_API_KEY` | Your Google Gemini API key | `AIzaSy...` |
| `GEMINI_MODEL` | The Gemini model to use | `gemini-3-flash-preview` |

Get your free API key from [Google AI Studio](https://aistudio.google.com/apikey).

---

## Local Development

### 1. Clone and Setup

```bash
# Create virtual environment
python -m venv chatbot-venv
source chatbot-venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### 2. Configure Environment

Create a `.env` file in the project root:

```bash
cp .env.example .env
```

Edit `.env` with your values:

```env
GEMINI_API_KEY=your-api-key-here
GEMINI_MODEL=gemini-3-flash-preview
```

### 3. Run the Chatbot

```bash
python chatbot.py
```

Open http://localhost:7860 in your browser.

---

## Production Deployment (AWS)

For production, secrets are stored securely in **AWS Secrets Manager** instead of environment files.

### What Terraform Does

The `terraform-folder/` contains infrastructure-as-code that automates:

| Resource | Purpose |
|----------|---------|
| `aws_secretsmanager_secret` | Creates a secret named `gemini_api_key` |
| `aws_secretsmanager_secret_version` | Stores `GEMINI_API_KEY` and `GEMINI_MODEL` as encrypted JSON |

#### Secret Structure in AWS

```json
{
  "GEMINI_API_KEY": "your-api-key",
  "GEMINI_MODEL": "gemini-3-flash-preview"
}
```

### Deploy to AWS

#### 1. Configure Terraform Variables

Create `terraform-folder/terraform.tfvars`:

```hcl
gemini_api_key = "your-gemini-api-key"
gemini_model   = "gemini-3-flash-preview"
```

#### 2. Apply Terraform

```bash
cd terraform-folder
terraform init
terraform plan
terraform apply
```

#### 3. Run with AWS Secrets

```bash
USE_AWS_SECRETS=true python chatbot.py
```

The application will automatically fetch secrets from AWS Secrets Manager in `ap-south-1` region.

---

## Project Structure

```
gemini-chatbot/
├── chatbot.py              # Main application
├── config.py               # Configuration & secrets management
├── requirements.txt        # Python dependencies
├── .env.example            # Environment template
├── .gitignore              # Git ignore rules
└── terraform-folder/
    ├── main.tf             # AWS Secrets Manager secret
    ├── secrets.tf          # Secret values (JSON)
    ├── variables.tf        # Input variables
    ├── outputs.tf          # Output values
    ├── provider.tf         # AWS provider config
    └── terraform.tfvars    # Your values (gitignored)
```

---

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `USE_AWS_SECRETS` | `false` | Set to `true` to fetch from AWS Secrets Manager |
| `AWS_SECRET_NAME` | `gemini_api_key` | Name of the secret in AWS |
| `AWS_REGION` | `ap-south-1` | AWS region for Secrets Manager |
| `GEMINI_API_KEY` | - | API key (when not using AWS) |
| `GEMINI_MODEL` | `gemini-3-flash-preview` | Model name |

---

