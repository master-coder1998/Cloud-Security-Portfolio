#!/usr/bin/env python3
"""
SECURE PATTERN - Production-ready credential management

Uses AWS Secrets Manager with proper error handling and caching.
"""

import json
import boto3
from botocore.exceptions import ClientError
import psycopg2

secrets_client = boto3.client('secretsmanager', region_name='us-east-1')

# Cache for secrets to reduce API calls
_secret_cache = {}

def get_secret(secret_name, use_cache=True):
    """
    Retrieve secret from AWS Secrets Manager with caching.
    
    Args:
        secret_name: Name or ARN of the secret
        use_cache: Whether to use cached value
    
    Returns:
        dict: Parsed secret value
    """
    if use_cache and secret_name in _secret_cache:
        return _secret_cache[secret_name]
    
    try:
        response = secrets_client.get_secret_value(SecretId=secret_name)
        secret = json.loads(response['SecretString'])
        
        if use_cache:
            _secret_cache[secret_name] = secret
        
        return secret
    
    except ClientError as e:
        error_code = e.response['Error']['Code']
        if error_code == 'ResourceNotFoundException':
            raise ValueError(f"Secret {secret_name} not found")
        elif error_code == 'InvalidRequestException':
            raise ValueError(f"Invalid request for secret {secret_name}")
        elif error_code == 'InvalidParameterException':
            raise ValueError(f"Invalid parameter for secret {secret_name}")
        elif error_code == 'DecryptionFailure':
            raise RuntimeError(f"Cannot decrypt secret {secret_name}")
        elif error_code == 'AccessDeniedException':
            raise PermissionError(f"Access denied to secret {secret_name}")
        else:
            raise

def connect_to_database():
    """Connect to database using credentials from Secrets Manager"""
    secret = get_secret('secrets-mgmt-dev-db-credentials')
    
    conn = psycopg2.connect(
        host=secret['host'],
        port=secret['port'],
        user=secret['username'],
        password=secret['password'],
        dbname=secret['dbname']
    )
    return conn

def call_external_api():
    """Make API call using key from Secrets Manager"""
    import requests
    
    secret = get_secret('secrets-mgmt-dev-external-api-key')
    api_key = secret.get('api_key')
    
    headers = {"Authorization": f"Bearer {api_key}"}
    response = requests.get("https://api.example.com/data", headers=headers)
    return response.json()

def get_oauth_token():
    """Get OAuth token using credentials from Secrets Manager"""
    import requests
    
    secret = get_secret('secrets-mgmt-dev-oauth-credentials')
    
    response = requests.post(
        secret['token_url'],
        data={
            'grant_type': 'client_credentials',
            'client_id': secret['client_id'],
            'client_secret': secret['client_secret']
        }
    )
    return response.json()['access_token']

# BENEFITS:
# - No credentials in source code or version control
# - Automatic rotation without code changes
# - Scoped IAM permissions limit blast radius
# - Full audit trail via CloudTrail
# - Centralized revocation and management
# - Encryption at rest with KMS
