"""
Sample Application with Intentional Security Issues
This demonstrates what the security pipeline will catch
"""

import os
import sqlite3
import subprocess

# SECURITY ISSUE 1: Hardcoded credentials (will be caught by Gitleaks)
# AWS_ACCESS_KEY = "AKIAIOSFODNN7EXAMPLE"  # Commented out to avoid triggering in repo
# AWS_SECRET_KEY = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"

# SECURITY ISSUE 2: SQL Injection vulnerability (will be caught by Semgrep/Bandit)
def get_user_unsafe(username):
    """
    Vulnerable to SQL injection
    """
    conn = sqlite3.connect('users.db')
    cursor = conn.cursor()
    
    # BAD: String concatenation in SQL query
    query = f"SELECT * FROM users WHERE username = '{username}'"
    cursor.execute(query)
    
    result = cursor.fetchone()
    conn.close()
    return result

# SECURITY ISSUE 3: Command injection vulnerability (will be caught by Bandit)
def ping_host_unsafe(hostname):
    """
    Vulnerable to command injection
    """
    # BAD: Using shell=True with user input
    result = subprocess.run(f"ping -c 1 {hostname}", shell=True, capture_output=True)
    return result.stdout

# SECURITY ISSUE 4: Insecure deserialization (will be caught by Semgrep)
def load_config_unsafe(config_data):
    """
    Vulnerable to arbitrary code execution
    """
    import pickle
    # BAD: Unpickling untrusted data
    config = pickle.loads(config_data)
    return config

# SECURITY ISSUE 5: Weak cryptography (will be caught by Bandit)
def hash_password_weak(password):
    """
    Uses weak hashing algorithm
    """
    import hashlib
    # BAD: MD5 is cryptographically broken
    return hashlib.md5(password.encode()).hexdigest()

# SECURITY ISSUE 6: Path traversal vulnerability (will be caught by Semgrep)
def read_file_unsafe(filename):
    """
    Vulnerable to path traversal
    """
    # BAD: No validation of filename
    with open(f"/var/data/{filename}", 'r') as f:
        return f.read()

# SECURE ALTERNATIVES (for comparison)

def get_user_safe(username):
    """
    Safe version using parameterized queries
    """
    conn = sqlite3.connect('users.db')
    cursor = conn.cursor()
    
    # GOOD: Parameterized query
    query = "SELECT * FROM users WHERE username = ?"
    cursor.execute(query, (username,))
    
    result = cursor.fetchone()
    conn.close()
    return result

def ping_host_safe(hostname):
    """
    Safe version with input validation
    """
    import re
    
    # GOOD: Validate input and avoid shell=True
    if not re.match(r'^[a-zA-Z0-9.-]+$', hostname):
        raise ValueError("Invalid hostname")
    
    result = subprocess.run(['ping', '-c', '1', hostname], capture_output=True)
    return result.stdout

def hash_password_safe(password):
    """
    Uses strong hashing with salt
    """
    import hashlib
    import secrets
    
    # GOOD: Use strong algorithm with salt
    salt = secrets.token_hex(16)
    password_hash = hashlib.pbkdf2_hmac('sha256', password.encode(), salt.encode(), 100000)
    return f"{salt}:{password_hash.hex()}"

def read_file_safe(filename):
    """
    Safe version with path validation
    """
    import os
    
    # GOOD: Validate and sanitize path
    base_dir = "/var/data"
    filepath = os.path.normpath(os.path.join(base_dir, filename))
    
    if not filepath.startswith(base_dir):
        raise ValueError("Invalid file path")
    
    with open(filepath, 'r') as f:
        return f.read()

if __name__ == "__main__":
    print("This is a sample application with intentional vulnerabilities")
    print("The security pipeline will detect and block these issues")
