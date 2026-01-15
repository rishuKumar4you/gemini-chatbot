"""
Configuration module for Gemini Chatbot.

Handles loading secrets from:
1. AWS Secrets Manager (when deployed)
2. Environment variables
3. .env file (for local development)

Priority: AWS Secrets Manager > Environment Variables > .env file
"""

import os
import json
from dotenv import load_dotenv

# Load .env file for local development
load_dotenv()


def get_aws_secret(secret_name: str, region_name: str = "us-east-1") -> dict | None:
    """
    Fetch secrets from AWS Secrets Manager.
    
    Args:
        secret_name: Name of the secret in AWS Secrets Manager
        region_name: AWS region where the secret is stored
    
    Returns:
        Dictionary containing secret key-value pairs, or None if not available
    """
    try:
        import boto3
        from botocore.exceptions import ClientError, NoCredentialsError
        
        client = boto3.client(
            service_name="secretsmanager",
            region_name=region_name
        )
        
        response = client.get_secret_value(SecretId=secret_name)
        
        # Parse the secret string (assuming JSON format)
        if "SecretString" in response:
            return json.loads(response["SecretString"])
        
    except ImportError:
        print("⚠️  boto3 not installed. Falling back to environment variables.")
    except NoCredentialsError:
        print("⚠️  AWS credentials not configured. Falling back to environment variables.")
    except ClientError as e:
        error_code = e.response.get("Error", {}).get("Code", "Unknown")
        if error_code == "ResourceNotFoundException":
            print(f"⚠️  Secret '{secret_name}' not found in AWS Secrets Manager.")
        elif error_code == "AccessDeniedException":
            print(f"⚠️  Access denied to secret '{secret_name}'.")
        else:
            print(f"⚠️  AWS Secrets Manager error: {error_code}")
    except Exception as e:
        print(f"⚠️  Error fetching from AWS Secrets Manager: {e}")
    
    return None


class Config:
    """Configuration class for the Gemini Chatbot application."""
    
    # AWS Secrets Manager configuration
    # Default values match your Terraform configuration
    AWS_SECRET_NAME = os.getenv("AWS_SECRET_NAME", "gemini_api_key")
    AWS_REGION = os.getenv("AWS_REGION", "ap-south-1")
    
    # Flag to enable/disable AWS Secrets Manager
    USE_AWS_SECRETS = os.getenv("USE_AWS_SECRETS", "false").lower() == "true"
    
    _secrets_cache: dict | None = None
    
    @classmethod
    def _load_secrets(cls) -> dict:
        """Load secrets from AWS or return empty dict."""
        if cls._secrets_cache is not None:
            return cls._secrets_cache
        
        if cls.USE_AWS_SECRETS:
            print("🔐 Attempting to fetch secrets from AWS Secrets Manager...")
            cls._secrets_cache = get_aws_secret(cls.AWS_SECRET_NAME, cls.AWS_REGION)
            if cls._secrets_cache:
                print("✅ Successfully loaded secrets from AWS Secrets Manager")
                return cls._secrets_cache
        
        cls._secrets_cache = {}
        return cls._secrets_cache
    
    @classmethod
    def get(cls, key: str, default: str | None = None) -> str | None:
        """
        Get a configuration value.
        
        Priority:
        1. AWS Secrets Manager (if USE_AWS_SECRETS=true)
        2. Environment variable
        3. Default value
        
        Args:
            key: The configuration key to look up
            default: Default value if key is not found
        
        Returns:
            The configuration value or default
        """
        # Try AWS Secrets Manager first (if enabled)
        secrets = cls._load_secrets()
        if key in secrets:
            return secrets[key]
        
        # Fall back to environment variables (which includes .env via python-dotenv)
        return os.getenv(key, default)
    
    @classmethod
    def get_gemini_api_key(cls) -> str | None:
        """Get the Gemini API key."""
        # Try multiple possible key names
        return (
            cls.get("GEMINI_API_KEY") or 
            cls.get("TF_VAR_gemini_api_key")
        )
    
    @classmethod
    def get_gemini_model(cls) -> str:
        """Get the Gemini model name."""
        return cls.get("GEMINI_MODEL", "gemini-3-flash-preview")


# Convenience function for quick access
def get_config(key: str, default: str | None = None) -> str | None:
    """Get a configuration value."""
    return Config.get(key, default)
