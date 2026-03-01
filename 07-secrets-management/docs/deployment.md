# Deployment Guide

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.0 installed
- Python 3.11 for Lambda function
- IAM permissions to create:
  - Secrets Manager secrets
  - KMS keys
  - Lambda functions
  - IAM roles and policies
  - CloudWatch resources

---

## Deployment Steps

### 1. Prepare Lambda Deployment Package

```bash
cd terraform/lambda
zip rotation.zip rotation.py
cd ../..
```

### 2. Configure Variables

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:
```hcl
aws_region    = "us-east-1"
environment   = "dev"
project_name  = "secrets-mgmt"
rotation_days = 30
```

### 3. Initialize Terraform

```bash
terraform init
```

### 4. Review Plan

```bash
terraform plan
```

Expected resources:
- 3 Secrets Manager secrets
- 2 KMS keys
- 1 Lambda function
- 4 IAM roles
- 6 IAM policies
- 4 CloudWatch resources

### 5. Deploy Infrastructure

```bash
terraform apply
```

Review and type `yes` to confirm.

### 6. Verify Deployment

```bash
# List secrets
aws secretsmanager list-secrets --query 'SecretList[?contains(Name, `secrets-mgmt`)].Name'

# Verify rotation is enabled
aws secretsmanager describe-secret --secret-id secrets-mgmt-dev-db-credentials

# Check Lambda function
aws lambda get-function --function-name secrets-mgmt-rotate-secret
```

---

## Post-Deployment Configuration

### Update Secret Values

The initial secret values are placeholders. Update with real credentials:

```bash
# Update database credentials
aws secretsmanager put-secret-value \
  --secret-id secrets-mgmt-dev-db-credentials \
  --secret-string '{
    "username": "actual_db_user",
    "password": "actual_db_password",
    "engine": "postgres",
    "host": "actual-db-host.rds.amazonaws.com",
    "port": 5432,
    "dbname": "production"
  }'

# Update API key
aws secretsmanager put-secret-value \
  --secret-id secrets-mgmt-dev-external-api-key \
  --secret-string '{
    "api_key": "actual_api_key_value"
  }'
```

### Configure CloudWatch Alarms

Add SNS topic for alarm notifications:

```bash
# Create SNS topic
aws sns create-topic --name secrets-management-alerts

# Subscribe email
aws sns subscribe \
  --topic-arn arn:aws:sns:us-east-1:ACCOUNT_ID:secrets-management-alerts \
  --protocol email \
  --notification-endpoint security-team@example.com

# Update alarms to use SNS topic
aws cloudwatch put-metric-alarm \
  --alarm-name secrets-mgmt-failed-secret-access \
  --alarm-actions arn:aws:sns:us-east-1:ACCOUNT_ID:secrets-management-alerts \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 1 \
  --metric-name FailedSecretAccess \
  --namespace SecretsManager \
  --period 300 \
  --statistic Sum \
  --threshold 5
```

---

## Testing

### Test Secret Retrieval

```python
import boto3
import json

client = boto3.client('secretsmanager')
response = client.get_secret_value(SecretId='secrets-mgmt-dev-db-credentials')
secret = json.loads(response['SecretString'])
print(f"Retrieved credentials for user: {secret['username']}")
```

### Test Rotation (Manual Trigger)

```bash
aws secretsmanager rotate-secret \
  --secret-id secrets-mgmt-dev-db-credentials
```

Monitor rotation progress:
```bash
aws secretsmanager describe-secret \
  --secret-id secrets-mgmt-dev-db-credentials \
  --query 'RotationEnabled'
```

### Test IAM Permissions

Assume application role and verify access:
```bash
# Assume app role
aws sts assume-role \
  --role-arn arn:aws:iam::ACCOUNT_ID:role/secrets-mgmt-app-role \
  --role-session-name test-session

# Try to access DB secret (should succeed)
aws secretsmanager get-secret-value \
  --secret-id secrets-mgmt-dev-db-credentials

# Try to access API secret (should fail)
aws secretsmanager get-secret-value \
  --secret-id secrets-mgmt-dev-external-api-key
```

---

## Integration with Applications

### Python Application

```python
import boto3
import json

def get_db_connection():
    client = boto3.client('secretsmanager')
    response = client.get_secret_value(SecretId='secrets-mgmt-dev-db-credentials')
    secret = json.loads(response['SecretString'])
    
    import psycopg2
    conn = psycopg2.connect(
        host=secret['host'],
        port=secret['port'],
        user=secret['username'],
        password=secret['password'],
        dbname=secret['dbname']
    )
    return conn
```

### Node.js Application

```javascript
const AWS = require('aws-sdk');
const client = new AWS.SecretsManager({ region: 'us-east-1' });

async function getDbConnection() {
  const data = await client.getSecretValue({
    SecretId: 'secrets-mgmt-dev-db-credentials'
  }).promise();
  
  const secret = JSON.parse(data.SecretString);
  
  const { Client } = require('pg');
  const dbClient = new Client({
    host: secret.host,
    port: secret.port,
    user: secret.username,
    password: secret.password,
    database: secret.dbname
  });
  
  await dbClient.connect();
  return dbClient;
}
```

### Environment Variables (Container)

For ECS/Fargate, reference secrets in task definition:

```json
{
  "containerDefinitions": [{
    "name": "app",
    "secrets": [
      {
        "name": "DB_HOST",
        "valueFrom": "arn:aws:secretsmanager:us-east-1:ACCOUNT_ID:secret:secrets-mgmt-dev-db-credentials:host::"
      },
      {
        "name": "DB_PASSWORD",
        "valueFrom": "arn:aws:secretsmanager:us-east-1:ACCOUNT_ID:secret:secrets-mgmt-dev-db-credentials:password::"
      }
    ]
  }]
}
```

---

## Troubleshooting

### Rotation Fails

Check Lambda logs:
```bash
aws logs tail /aws/lambda/secrets-mgmt-rotate-secret --follow
```

Common issues:
- Lambda lacks network access to database
- Database user lacks permission to change password
- Secret format doesn't match expected structure

### Access Denied Errors

Verify IAM permissions:
```bash
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::ACCOUNT_ID:role/secrets-mgmt-app-role \
  --action-names secretsmanager:GetSecretValue \
  --resource-arns arn:aws:secretsmanager:us-east-1:ACCOUNT_ID:secret:secrets-mgmt-dev-db-credentials
```

### KMS Decryption Failures

Check KMS key policy and IAM role has kms:Decrypt permission.

---

## Cleanup

To destroy all resources:

```bash
cd terraform
terraform destroy
```

Note: Secrets have a 7-day recovery window. To force immediate deletion:

```bash
aws secretsmanager delete-secret \
  --secret-id secrets-mgmt-dev-db-credentials \
  --force-delete-without-recovery
```

---

## Production Considerations

### High Availability
- Deploy Lambda in multiple AZs
- Use VPC endpoints for Secrets Manager
- Configure retry logic in applications

### Performance
- Cache secrets in application memory (refresh periodically)
- Use connection pooling for databases
- Monitor GetSecretValue API throttling

### Security
- Enable VPC endpoints to avoid internet traffic
- Use resource-based policies on secrets
- Implement secret scanning in CI/CD
- Regular access reviews of IAM policies

### Cost Optimization
- Consolidate related secrets into single JSON object
- Implement client-side caching to reduce API calls
- Use CloudWatch Logs Insights for cost analysis
