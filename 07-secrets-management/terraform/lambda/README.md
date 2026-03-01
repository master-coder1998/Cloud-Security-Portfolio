# Lambda Rotation Function

This directory contains the Lambda function for rotating secrets in AWS Secrets Manager.

## Files

- `rotation.py` - Python code implementing 4-step rotation process
- `rotation.zip` - Deployment package (auto-generated)

## Building Deployment Package

If you need to rebuild the deployment package:

```bash
# Windows
powershell Compress-Archive -Path rotation.py -DestinationPath rotation.zip -Force

# Linux/Mac
zip rotation.zip rotation.py
```

## Rotation Process

The function implements AWS Secrets Manager's 4-step rotation:

1. **createSecret** - Generate new password and store as AWSPENDING
2. **setSecret** - Update database with new password
3. **testSecret** - Verify new credentials work
4. **finishSecret** - Move AWSCURRENT label to new version

## Customization

For production use, modify `set_secret()` and `test_secret()` functions to:
- Connect to your actual database
- Execute password change commands
- Test connectivity with new credentials
