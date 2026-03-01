import json
import boto3
import os

secrets_client = boto3.client('secretsmanager')

def lambda_handler(event, context):
    """
    Handles secret rotation for AWS Secrets Manager.
    Implements the four-step rotation process.
    """
    arn = event['SecretId']
    token = event['ClientRequestToken']
    step = event['Step']
    
    metadata = secrets_client.describe_secret(SecretId=arn)
    if not metadata['RotationEnabled']:
        raise ValueError(f"Secret {arn} is not enabled for rotation")
    
    versions = metadata['VersionIdsToStages']
    if token not in versions:
        raise ValueError(f"Secret version {token} has no stage for rotation")
    
    if "AWSCURRENT" in versions[token]:
        return
    elif "AWSPENDING" not in versions[token]:
        raise ValueError(f"Secret version {token} not set as AWSPENDING for rotation")
    
    if step == "createSecret":
        create_secret(arn, token)
    elif step == "setSecret":
        set_secret(arn, token)
    elif step == "testSecret":
        test_secret(arn, token)
    elif step == "finishSecret":
        finish_secret(arn, token)
    else:
        raise ValueError(f"Invalid step parameter: {step}")

def create_secret(arn, token):
    """Generate new secret value"""
    try:
        secrets_client.get_secret_value(SecretId=arn, VersionId=token, VersionStage="AWSPENDING")
        return
    except secrets_client.exceptions.ResourceNotFoundException:
        pass
    
    current_secret = secrets_client.get_secret_value(SecretId=arn, VersionStage="AWSCURRENT")
    secret_dict = json.loads(current_secret['SecretString'])
    
    # Generate new password
    new_password = secrets_client.get_random_password(
        PasswordLength=32,
        ExcludeCharacters='/@"\'\\'
    )
    secret_dict['password'] = new_password['RandomPassword']
    
    secrets_client.put_secret_value(
        SecretId=arn,
        ClientRequestToken=token,
        SecretString=json.dumps(secret_dict),
        VersionStages=['AWSPENDING']
    )

def set_secret(arn, token):
    """Update the database with new credentials"""
    pending_secret = secrets_client.get_secret_value(SecretId=arn, VersionId=token, VersionStage="AWSPENDING")
    secret_dict = json.loads(pending_secret['SecretString'])
    
    # In production, connect to database and update password
    # This is a placeholder for the actual database update logic
    print(f"Would update database password for user: {secret_dict['username']}")

def test_secret(arn, token):
    """Test new credentials work"""
    pending_secret = secrets_client.get_secret_value(SecretId=arn, VersionId=token, VersionStage="AWSPENDING")
    secret_dict = json.loads(pending_secret['SecretString'])
    
    # In production, test database connection with new credentials
    print(f"Would test connection for user: {secret_dict['username']}")

def finish_secret(arn, token):
    """Finalize rotation by updating version stages"""
    metadata = secrets_client.describe_secret(SecretId=arn)
    current_version = None
    
    for version, stages in metadata['VersionIdsToStages'].items():
        if "AWSCURRENT" in stages:
            if version == token:
                return
            current_version = version
            break
    
    secrets_client.update_secret_version_stage(
        SecretId=arn,
        VersionStage="AWSCURRENT",
        MoveToVersionId=token,
        RemoveFromVersionId=current_version
    )
