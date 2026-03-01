# Project 7: Secrets Management

**Domain:** Credential Hygiene  
**Skills:** AWS Secrets Manager, rotation policies, blast radius reduction, KMS encryption

---

## Overview

Hardcoded credentials and long-lived access keys are consistently among the most exploited vulnerabilities in cloud environments. A single exposed API key or database password can provide attackers with persistent access, and manual rotation processes are error-prone and rarely executed.

This project implements a production-grade secrets management architecture using AWS Secrets Manager. It demonstrates automatic credential rotation, blast radius reduction through scoped IAM policies, and monitoring for anomalous access patterns. The focus is on building a system that makes secure credential management the default path, not an afterthought.

---

## Problem Statement

### Common Anti-Patterns

1. **Hardcoded Credentials**
   - Database passwords in application code
   - API keys committed to version control
   - Credentials in configuration files

2. **Long-Lived Static Credentials**
   - Passwords unchanged for months or years
   - No rotation mechanism
   - Manual rotation requires downtime

3. **Overly Broad Access**
   - Single credential used by multiple services
   - No way to trace which service accessed what
   - Compromise affects entire infrastructure

4. **No Audit Trail**
   - Cannot determine who accessed credentials
   - No alerting on suspicious access patterns
   - Impossible to investigate incidents

---

## Solution Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Application Layer                        │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │ Web App  │  │   API    │  │ Worker   │  │  Admin   │    │
│  │  (EC2)   │  │ Service  │  │ Process  │  │  Tools   │    │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘    │
│       │             │             │             │          │
│       │ Role A      │ Role B      │ Role A      │ Role C   │
│       │ (DB only)   │ (API only)  │ (DB only)   │ (All)    │
└───────┼─────────────┼─────────────┼─────────────┼──────────┘
        │             │             │             │
        └─────────────┴─────────────┴─────────────┘
                      │
        ┌─────────────┴─────────────┐
        │  AWS Secrets Manager      │
        ├───────────────────────────┤
        │  DB Credentials           │ ← Auto-rotate 30 days
        │  API Keys                 │ ← Manual rotation
        │  OAuth Credentials        │ ← Manual rotation
        └─────────────┬─────────────┘
                      │
        ┌─────────────┴─────────────┐
        │  KMS Encryption           │
        ├───────────────────────────┤
        │  Key 1: DB Secrets        │ ← Separate keys for
        │  Key 2: API Secrets       │   blast radius control
        └─────────────┬─────────────┘
                      │
        ┌─────────────┴─────────────┐
        │  Monitoring & Audit       │
        ├───────────────────────────┤
        │  CloudWatch Alarms        │
        │  CloudTrail Logs          │
        └───────────────────────────┘
```

---

## Key Features

### 1. Automatic Rotation
Database credentials rotate every 30 days using Lambda-based rotation. The four-step rotation process ensures zero downtime by maintaining both old and new credentials during transition.

### 2. Blast Radius Reduction
Each application component has access only to the specific secrets it needs:
- Web application: database credentials only
- API service: third-party API keys only
- Admin tools: all secrets

Compromise of one component doesn't expose credentials for others.

### 3. Encryption at Rest
All secrets encrypted with KMS customer-managed keys. Separate keys for different secret types provide additional isolation and enable granular access control.

### 4. Monitoring and Alerting
CloudWatch alarms trigger on:
- Failed secret access attempts (threshold: 5 in 5 minutes)
- Rotation failures
- Unauthorized access attempts

All secret operations logged to CloudTrail for audit and investigation.

### 5. Version Management
Secrets Manager maintains multiple versions:
- AWSCURRENT: Active version used by applications
- AWSPENDING: New version during rotation
- AWSPREVIOUS: Previous version for rollback

---

## Implementation Details

### Terraform Resources

**Secrets:**
- `aws_secretsmanager_secret.db_credentials` - Database credentials with rotation
- `aws_secretsmanager_secret.api_key` - Third-party API key
- `aws_secretsmanager_secret.oauth_credentials` - OAuth client credentials

**Encryption:**
- `aws_kms_key.secrets` - KMS key for general secrets
- `aws_kms_key.rds_secrets` - Dedicated KMS key for database credentials

**Rotation:**
- `aws_lambda_function.rotate_secret` - Rotation function
- `aws_secretsmanager_secret_rotation.db_credentials` - Rotation schedule

**Access Control:**
- `aws_iam_role.app_role` - Application role (database access only)
- `aws_iam_role.api_service_role` - API service role (API keys only)

**Monitoring:**
- `aws_cloudwatch_log_group.secret_access` - Secret access logs
- `aws_cloudwatch_metric_alarm.failed_secret_access` - Failed access alarm
- `aws_cloudwatch_metric_alarm.rotation_failure` - Rotation failure alarm

---

## Security Controls

### What This Mitigates

| Threat | Control | Effectiveness |
|--------|---------|---------------|
| Hardcoded credentials | Dynamic retrieval from Secrets Manager | High |
| Credential exposure in VCS | No secrets in code or config | High |
| Long-lived credentials | Automatic 30-day rotation | High |
| Lateral movement | Scoped IAM policies per secret | Medium |
| Unauthorized access | IAM + KMS + monitoring | Medium |
| Credential reuse | Separate secrets per service | High |

### Limitations

- **Application vulnerabilities**: Secrets Manager doesn't prevent SQL injection or other app-level attacks
- **Compromised IAM roles**: If an IAM role with secret access is compromised, attacker can retrieve secrets
- **Insider threats**: Legitimate access cannot be prevented, only audited
- **Secrets in logs**: Applications must avoid logging secret values

---

## Cost Analysis

### Monthly Costs (3 secrets, 5,000 API calls)

| Component | Cost |
|-----------|------|
| Secrets Manager secrets (3 × $0.40) | $1.20 |
| Secrets Manager API calls | $0.03 |
| KMS keys (2 × $1.00) | $2.00 |
| KMS API calls | $0.02 |
| Lambda execution | $0.00 |
| CloudWatch Logs | $0.05 |
| **Total** | **$3.30/month** |

### ROI Calculation

Cost of single credential breach:
- Incident response: $5,000 - $50,000
- Notification and remediation: $10,000+
- Regulatory fines: $100,000+
- Reputation damage: Immeasurable

**ROI: 1,500x - 15,000x**

---

## Deployment

### Prerequisites
- AWS CLI configured
- Terraform >= 1.0
- Python 3.11
- IAM permissions for Secrets Manager, KMS, Lambda, IAM

### Quick Start

```bash
# Create Lambda deployment package
cd terraform/lambda
zip rotation.zip rotation.py

# Configure variables
cd ..
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# Deploy
terraform init
terraform plan
terraform apply
```

See [docs/deployment.md](docs/deployment.md) for detailed instructions.

---

## Usage Examples

### Secure Pattern (Python)

```python
import boto3
import json

def get_db_connection():
    client = boto3.client('secretsmanager')
    response = client.get_secret_value(
        SecretId='secrets-mgmt-dev-db-credentials'
    )
    secret = json.loads(response['SecretString'])
    
    import psycopg2
    return psycopg2.connect(
        host=secret['host'],
        user=secret['username'],
        password=secret['password'],
        dbname=secret['dbname']
    )
```

### Insecure Pattern (Don't Do This)

```python
# ANTI-PATTERN: Hardcoded credentials
DB_PASSWORD = "SuperSecret123!"  # Exposed in source code
conn = psycopg2.connect(
    host="prod-db.example.com",
    user="admin",
    password=DB_PASSWORD
)
```

See [examples/](examples/) for complete code samples.

---

## Testing

### Test Secret Retrieval
```bash
aws secretsmanager get-secret-value \
  --secret-id secrets-mgmt-dev-db-credentials
```

### Test Rotation
```bash
aws secretsmanager rotate-secret \
  --secret-id secrets-mgmt-dev-db-credentials
```

### Test IAM Permissions
```bash
# Assume app role and verify scoped access
aws sts assume-role \
  --role-arn arn:aws:iam::ACCOUNT_ID:role/secrets-mgmt-app-role \
  --role-session-name test
```

---

## Monitoring

### CloudWatch Alarms

1. **Failed Secret Access**
   - Threshold: > 5 failures in 5 minutes
   - Indicates: Potential unauthorized access attempt or misconfigured IAM

2. **Rotation Failure**
   - Threshold: > 0 failures
   - Indicates: Lambda error, network issue, or database permission problem

### CloudTrail Events

All secret operations logged:
- `GetSecretValue` - Who accessed which secret
- `PutSecretValue` - Manual secret updates
- `RotateSecret` - Rotation triggers
- `DeleteSecret` - Deletion attempts

---

## Operational Procedures

### Adding a New Secret
1. Create secret in Secrets Manager with appropriate KMS key
2. Create IAM policy granting GetSecretValue to specific role
3. Update application to retrieve secret dynamically
4. Test in non-production environment
5. Deploy to production

### Rotating a Secret Manually
1. Generate new credential value
2. Update secret in Secrets Manager
3. Test application with new version
4. Monitor for errors
5. Old version retained for rollback

### Responding to Compromise
1. Immediately rotate affected secret
2. Review CloudTrail logs for unauthorized access
3. Identify and remediate compromise vector
4. Update IAM policies if needed
5. Document incident

---

## Production Hardening

### Additional Security Measures

1. **VPC Endpoints**
   - Use VPC endpoints for Secrets Manager to avoid internet traffic
   - Reduces attack surface and improves performance

2. **Resource Policies**
   - Add resource-based policies to secrets for defense in depth
   - Enforce additional conditions (source VPC, IP ranges)

3. **Secret Scanning**
   - Implement git hooks to prevent accidental secret commits
   - Use tools like Gitleaks or TruffleHog in CI/CD

4. **Rotation Testing**
   - Regularly test rotation in non-prod environments
   - Validate applications handle rotation gracefully

5. **Backup and Recovery**
   - Store backup secrets in separate AWS account
   - Document disaster recovery procedures

---

## Compliance Mapping

| Standard | Requirement | Implementation |
|----------|-------------|----------------|
| PCI-DSS 8.2.4 | Change passwords every 90 days | 30-day automatic rotation |
| SOC 2 CC6.1 | Logical access controls | IAM policies per secret |
| HIPAA 164.312(a)(2)(iv) | Encryption at rest | KMS encryption |
| ISO 27001 A.9.4.3 | Password management system | Secrets Manager |
| NIST 800-53 IA-5 | Authenticator management | Rotation + monitoring |

---

## Lessons Learned

### What Worked Well
- Separate KMS keys per secret type simplified access control
- Version staging enabled zero-downtime rotation
- Scoped IAM policies effectively limited blast radius
- CloudWatch alarms caught rotation failures immediately

### Challenges
- Lambda rotation function requires careful error handling
- Applications must implement retry logic for transient failures
- Initial secret values must be updated post-deployment
- Testing rotation requires actual database connection

### Production Recommendations
1. Start with manual rotation to validate process
2. Enable automatic rotation only after thorough testing
3. Implement client-side caching to reduce API calls
4. Monitor CloudWatch metrics for throttling
5. Document runbooks for common failure scenarios

---

## Extensions

### Potential Enhancements
1. **Multi-Region Replication**: Replicate secrets to secondary region for DR
2. **Secret Versioning UI**: Build dashboard for secret version history
3. **Automated Remediation**: Lambda function to auto-remediate failed rotations
4. **Integration Testing**: Automated tests for rotation process
5. **Cost Optimization**: Consolidate related secrets to reduce API calls

---

## References

- [AWS Secrets Manager Documentation](https://docs.aws.amazon.com/secretsmanager/)
- [Secrets Manager Rotation](https://docs.aws.amazon.com/secretsmanager/latest/userguide/rotating-secrets.html)
- [KMS Best Practices](https://docs.aws.amazon.com/kms/latest/developerguide/best-practices.html)
- [IAM Policy Examples](https://docs.aws.amazon.com/secretsmanager/latest/userguide/auth-and-access_examples.html)

---

## License

MIT License - See repository root for details.
