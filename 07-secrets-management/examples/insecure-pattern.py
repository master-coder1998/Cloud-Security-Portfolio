#!/usr/bin/env python3
"""
INSECURE PATTERN - DO NOT USE IN PRODUCTION

This demonstrates common anti-patterns in credential management.
"""

import psycopg2

# ANTI-PATTERN 1: Hardcoded credentials
DB_HOST = "prod-db.example.com"
DB_USER = "admin"
DB_PASSWORD = "SuperSecret123!"  # Exposed in source code
DB_NAME = "production"

# ANTI-PATTERN 2: Credentials in environment variables (better but still risky)
import os
API_KEY = os.getenv("API_KEY", "default-key-12345")

# ANTI-PATTERN 3: Credentials in config files committed to git
config = {
    "database": {
        "host": "prod-db.example.com",
        "username": "admin",
        "password": "hardcoded-password"
    },
    "api": {
        "key": "sk_live_51234567890abcdef",
        "secret": "whsec_1234567890abcdef"
    }
}

def connect_to_database():
    """Connect using hardcoded credentials"""
    conn = psycopg2.connect(
        host=DB_HOST,
        user=DB_USER,
        password=DB_PASSWORD,
        dbname=DB_NAME
    )
    return conn

def call_external_api():
    """Make API call with hardcoded key"""
    import requests
    headers = {"Authorization": f"Bearer {API_KEY}"}
    response = requests.get("https://api.example.com/data", headers=headers)
    return response.json()

# RISK SUMMARY:
# - Credentials exposed in source code and version control
# - No rotation mechanism
# - Blast radius: entire database if compromised
# - Audit trail: impossible to track which service used credentials
# - Revocation: requires code changes and redeployment
