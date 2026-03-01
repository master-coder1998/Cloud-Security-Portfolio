# Secrets Management Architecture

## Design Principles

### 1. Zero Trust for Credentials
No credentials stored in code, configuration files, or environment variables. All secrets retrieved dynamically from AWS Secrets Manager at runtime.

### 2. Blast Radius Reduction
Each application component has access only to the specific secrets it needs. Database credentials are isolated from API keys, preventing lateral movement if one component is compromised.

### 3. Automatic Rotation
Database credentials rotate every 30 days without manual intervention or application downtime. Rotation uses versioning to ensure zero-downtime transitions.

### 4. Defense in Depth
Multiple layers of protection:
- KMS encryption at rest
- IAM policies for access control
- CloudWatch monitoring for anomalies
- CloudTrail audit logging
- Version staging for safe rotation

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                      Application Layer                          │
├──────────────┬──────────────┬──────────────┬───────────────────┤
│  Web App     │  API Service │  Background  │  Admin Tools      │
│  (EC2)       │  (ECS)       │  Worker      │  (Lambda)         │
└──────┬───────┴──────┬───────┴──────┬───────┴──────┬────────────┘
       │              │              │              │
       │ IAM Role     │ IAM Role     │ IAM Role     │ IAM Role
       │ (DB only)    │ (API only)   │ (DB only)    │ (All)
       │              │              │              │
       └──────────────┴──────────────┴──────────────┘
                      │
       ┌──────────────┴──────────────┐
       │   AWS Secrets Manager       │
       ├─────────────────────────────┤
       │  ┌─────────────────────┐    │
       │  │ DB Credentials      │    │  ← Rotates every 30 days
       │  │ - AWSCURRENT        │    │
       │  │ - AWSPENDING        │    │
       │  └─────────────────────┘    │
       │                             │
       │  ┌─────────────────────┐    │
       │  │ API Keys            │    │  ← Manual rotation
       │  │ - AWSCURRENT        │    │
       │  └─────────────────────┘    │
       │                             │
       │  ┌─────────────────────┐    │
       │  │ OAuth Credentials   │    │  ← Manual rotation
       │  │ - AWSCURRENT        │    │
       │  └─────────────────────┘    │
       └──────────┬──────────────────┘
                  │
       ┌──────────┴──────────────┐
       │   KMS Encryption        │
       ├─────────────────────────┤
       │  Key 1: DB Secrets      │  ← Separate keys for
       │  Key 2: API Secrets     │     blast radius control
       └─────────────────────────┘
                  │
       ┌──────────┴──────────────┐
       │   Monitoring            │
       ├─────────────────────────┤
       │  CloudWatch Alarms      │
       │  - Failed access        │
       │  - Rotation failures    │
       │                         │
       │  CloudTrail Logs        │
       │  - All API calls        │
       │  - IAM activity         │
       └─────────────────────────┘
```

---

## Secret Types and Rotation Strategy

### Database Credentials
- **Rotation**: Automatic every 30 days
- **Method**: Lambda function implements 4-step rotation
- **Downtime**: Zero (version staging ensures smooth transition)
- **Blast radius**: Limited to database access only

### API Keys (Third-Party)
- **Rotation**: Manual (controlled by third party)
- **Method**: Update secret value via console/CLI
- **Blast radius**: Limited to specific API service

### OAuth Credentials
- **Rotation**: Manual or on-demand
- **Method**: Regenerate in OAuth provider, update secret
- **Blast radius**: Limited to OAuth-protected resources

---

## IAM Access Model

### Principle: Least Privilege by Secret
Each IAM role has access to exactly the secrets it needs, nothing more.

```
Web Application Role
├── GetSecretValue: db-credentials
└── Decrypt: kms-key-rds

API Service Role
├── GetSecretValue: api-key, oauth-credentials
└── Decrypt: kms-key-api

Admin Role
├── GetSecretValue: * (all secrets)
├── PutSecretValue: * (for manual updates)
└── Decrypt: * (all KMS keys)
```

### Condition Keys
All policies enforce version stage conditions:
```json
"Condition": {
  "StringEquals": {
    "secretsmanager:VersionStage": "AWSCURRENT"
  }
}
```

This prevents access to pending or deprecated secret versions.

---

## Rotation Process

### Four-Step Rotation (Zero Downtime)

```
Step 1: createSecret
├── Generate new password
├── Store as AWSPENDING version
└── Keep AWSCURRENT unchanged

Step 2: setSecret
├── Connect to database with AWSCURRENT credentials
├── Update password to AWSPENDING value
└── Database now accepts both old and new passwords

Step 3: testSecret
├── Attempt connection with AWSPENDING credentials
├── Verify access works
└── Rollback if test fails

Step 4: finishSecret
├── Move AWSCURRENT label to AWSPENDING version
├── Old version becomes AWSPREVIOUS
└── Applications now use new credentials
```

### Rollback Strategy
If rotation fails at any step:
1. AWSCURRENT remains unchanged
2. Applications continue using existing credentials
3. CloudWatch alarm triggers for investigation
4. Manual intervention only if repeated failures

---

## Monitoring and Alerting

### Metrics Tracked
1. **Failed Secret Access**: Threshold > 5 in 5 minutes
2. **Rotation Failures**: Threshold > 0
3. **Secret Age**: Alert if > 90 days without rotation
4. **Unauthorized Access Attempts**: Any denied GetSecretValue

### CloudTrail Events
All secret operations logged:
- GetSecretValue (who accessed what, when)
- PutSecretValue (manual updates)
- RotateSecret (rotation triggers)
- DeleteSecret (deletion attempts)

---

## Cost Analysis

### Monthly Costs (Estimated)

| Component | Unit Cost | Quantity | Monthly Cost |
|-----------|-----------|----------|--------------|
| Secrets Manager | $0.40/secret | 3 secrets | $1.20 |
| API Calls | $0.05/10k | ~5k calls | $0.03 |
| KMS Keys | $1.00/key | 2 keys | $2.00 |
| KMS API Calls | $0.03/10k | ~5k calls | $0.02 |
| Lambda (rotation) | $0.20/1M | 1k invocations | $0.00 |
| CloudWatch Logs | $0.50/GB | 0.1 GB | $0.05 |

**Total: ~$3.30/month**

### Cost vs. Risk
Single credential breach can cost:
- Incident response: $5,000 - $50,000
- Data breach notification: $10,000+
- Regulatory fines: $100,000+
- Reputation damage: Immeasurable

ROI on secrets management: 1,500x - 15,000x

---

## Security Considerations

### What This Solves
✓ Hardcoded credentials in source code  
✓ Credentials in version control  
✓ Long-lived static credentials  
✓ Overly broad credential access  
✓ No audit trail for credential usage  
✓ Manual rotation processes  

### What This Doesn't Solve
✗ Application vulnerabilities (SQL injection, etc.)  
✗ Compromised IAM roles with secret access  
✗ Insider threats with legitimate access  
✗ Secrets exposed in application logs  

### Additional Hardening
1. **VPC Endpoints**: Use VPC endpoints for Secrets Manager to avoid internet traffic
2. **Resource Policies**: Add resource-based policies to secrets for additional access control
3. **Secret Scanning**: Implement git hooks to prevent accidental secret commits
4. **Rotation Testing**: Regularly test rotation in non-prod environments

---

## Operational Procedures

### Adding a New Secret
1. Create secret in Secrets Manager with appropriate KMS key
2. Create IAM policy granting GetSecretValue to specific role
3. Update application code to retrieve secret
4. Test in non-production environment
5. Deploy to production

### Rotating a Secret Manually
1. Generate new credential value
2. Update secret in Secrets Manager (creates new version)
3. Test application with new version
4. Monitor for errors
5. Old version retained as AWSPREVIOUS for rollback

### Responding to Credential Compromise
1. Immediately rotate affected secret
2. Review CloudTrail logs for unauthorized access
3. Identify and remediate compromise vector
4. Update IAM policies if needed
5. Document incident for post-mortem

---

## Compliance Mapping

| Control | Requirement | Implementation |
|---------|-------------|----------------|
| PCI-DSS 8.2.4 | Change passwords every 90 days | Automatic 30-day rotation |
| SOC 2 CC6.1 | Logical access controls | IAM policies per secret |
| HIPAA 164.312(a)(2)(iv) | Encryption at rest | KMS encryption |
| ISO 27001 A.9.4.3 | Password management | Secrets Manager |
| NIST 800-53 IA-5 | Authenticator management | Rotation + monitoring |

---

## Production Readiness Checklist

- [ ] VPC endpoints configured for Secrets Manager
- [ ] Resource-based policies added to secrets
- [ ] SNS topic configured for CloudWatch alarms
- [ ] Rotation tested in staging environment
- [ ] Runbooks created for rotation failures
- [ ] Application code handles rotation gracefully
- [ ] CloudTrail logs forwarded to SIEM
- [ ] Backup secrets stored in separate account
- [ ] Disaster recovery procedures documented
- [ ] Team trained on secret management procedures
