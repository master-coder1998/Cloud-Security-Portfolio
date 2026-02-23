# Cross-Account IAM Architecture

## Design Decisions

### Why Role Assumption Over Long-Lived Credentials?

**Security Benefits:**
- **Temporary Credentials**: Sessions expire after 1 hour (configurable), limiting exposure window
- **Automatic Rotation**: No manual credential rotation needed
- **Audit Trail**: Every role assumption is logged in CloudTrail
- **MFA Support**: Can enforce MFA for sensitive operations
- **Centralized Control**: Revoke access by modifying trust policy, not distributing new credentials

**Operational Benefits:**
- **No Secret Management**: No need to store and distribute access keys
- **Consistent Access Pattern**: Same mechanism across all accounts
- **Easy Revocation**: Disable role in one place to revoke all access

### External ID: Preventing the Confused Deputy Problem

The External ID is a secret shared between the trusting and trusted accounts. It prevents:

1. **Scenario**: Attacker creates a role in their account with same name as your role
2. **Attack**: Tricks your service into assuming attacker's role instead
3. **Prevention**: External ID ensures only authorized accounts can assume the role

**Best Practices:**
- Generate a unique, random External ID (32+ characters)
- Store securely (e.g., AWS Secrets Manager, HashiCorp Vault)
- Never commit to version control
- Rotate periodically (quarterly recommended)

### MFA Requirement

All sensitive roles require MFA to assume. This provides:
- **Second Factor**: Even if credentials are compromised, attacker needs MFA device
- **Audit Signal**: MFA usage indicates human interaction, not automated process
- **Compliance**: Meets requirements for privileged access in most frameworks

### IP Restrictions

The Incident Response Role includes IP restrictions because:
- **Limited Use Case**: Only used during active incidents
- **Known Locations**: Incident responders work from known networks (VPN, office)
- **Additional Layer**: Even with stolen credentials + MFA, attacker needs to be on allowed network

**Trade-off**: May cause issues if incident responder needs access from unexpected location. Document break-glass procedure for this scenario.

### Session Duration

Set to 1 hour (3600 seconds) because:
- **Short Enough**: Limits blast radius if session token is compromised
- **Long Enough**: Allows completion of typical tasks without re-authentication
- **Audit Granularity**: More frequent assumptions = better audit trail

## Scaling Considerations

### Current Setup (3-5 Accounts)
- Manual role creation per account
- Individual trust policies
- Direct role ARN references

### Medium Scale (10-50 Accounts)
- Use AWS Organizations
- Deploy roles via CloudFormation StackSets
- Centralized trust policy management
- Automated role discovery

### Large Scale (100+ Accounts)
- Service Control Policies (SCPs) for guardrails
- Automated role provisioning via CI/CD
- Centralized identity provider (SSO)
- Role assumption through AWS SSO instead of direct AssumeRole

## Security Monitoring

### What to Alert On

**High Priority (Immediate Response):**
- Incident Response Role assumption (should be rare)
- Failed role assumption attempts (>3 in 5 minutes)
- Role assumption from unexpected IP addresses
- Trust policy modifications

**Medium Priority (Review within 1 hour):**
- Security Audit Role assumption outside business hours
- Role assumption from new IAM principals
- Changes to role permissions

**Low Priority (Daily Review):**
- All role assumptions (audit log)
- Session duration patterns
- Geographic distribution of access

### Detection Strategies

1. **CloudTrail Analysis**
   - Monitor `AssumeRole` API calls
   - Track `sourceIPAddress` for anomalies
   - Correlate with known incident tickets

2. **Behavioral Analysis**
   - Baseline normal assumption patterns
   - Alert on deviations (time, frequency, source)
   - Machine learning for anomaly detection (AWS GuardDuty)

3. **Compliance Checks**
   - Verify MFA was used (check `aws:MultiFactorAuthPresent`)
   - Validate External ID is present
   - Ensure session duration within policy

## Incident Response

### Compromised Role Scenario

**If you suspect a role has been compromised:**

1. **Immediate Actions** (< 5 minutes)
   - Modify trust policy to deny all assumptions
   - Revoke all active sessions (modify role policy to deny all)
   - Alert security team

2. **Investigation** (< 1 hour)
   - Review CloudTrail for all role assumptions in last 90 days
   - Identify unauthorized actions taken
   - Determine scope of compromise

3. **Remediation** (< 24 hours)
   - Rotate External ID
   - Review and update trust policy
   - Implement additional controls (IP restrictions, time-based access)
   - Update monitoring rules

4. **Post-Incident** (< 1 week)
   - Document lessons learned
   - Update runbooks
   - Conduct tabletop exercise
   - Review similar roles for same vulnerability

### Break-Glass Scenario

**If normal cross-account access is unavailable:**

1. Use break-glass credentials (see Project 6)
2. Document reason for break-glass usage
3. Restore normal access path
4. Conduct post-incident review

## Cost Considerations

**This architecture has minimal cost:**
- IAM roles: Free
- CloudTrail: Already enabled for organization
- CloudWatch Alarms: ~$0.10 per alarm per month
- CloudWatch Logs: Based on ingestion volume

**Estimated monthly cost**: < $5 for monitoring

## Compliance Mapping

| Control | Framework | Implementation |
|---------|-----------|----------------|
| Least Privilege | CIS, NIST | Scoped IAM policies |
| MFA for Privileged Access | PCI-DSS, SOC 2 | MFA condition in trust policy |
| Audit Logging | All | CloudTrail + CloudWatch |
| Separation of Duties | SOX, HIPAA | Different roles for different functions |
| Access Review | SOC 2, ISO 27001 | Quarterly trust policy review |

## Testing the Setup

### Validation Checklist

- [ ] Can assume Security Audit Role with MFA
- [ ] Cannot assume Security Audit Role without MFA
- [ ] Cannot assume role with wrong External ID
- [ ] Cannot assume Incident Response Role from unauthorized IP
- [ ] CloudWatch alarms fire on role assumption
- [ ] CloudTrail logs show all assumption attempts
- [ ] Session expires after configured duration
- [ ] Can perform expected actions with assumed role
- [ ] Cannot perform unauthorized actions

### Test Script

```bash
#!/bin/bash
# Test role assumption

ROLE_ARN="arn:aws:iam::222222222222:role/SecurityAuditRole"
EXTERNAL_ID="your-external-id"
MFA_SERIAL="arn:aws:iam::111111111111:mfa/your-user"
MFA_TOKEN="123456"

# Attempt to assume role
aws sts assume-role \
  --role-arn $ROLE_ARN \
  --role-session-name test-session \
  --external-id $EXTERNAL_ID \
  --serial-number $MFA_SERIAL \
  --token-code $MFA_TOKEN

# If successful, export credentials and test access
# If failed, verify error message matches expected failure mode
```

## Future Enhancements

1. **Automated Role Discovery**: Lambda function to discover and document all cross-account roles
2. **Just-In-Time Access**: Require approval before role assumption (AWS SSO + ServiceNow)
3. **Time-Bound Access**: Automatically revoke access after specified time
4. **Risk-Based Authentication**: Require additional verification for high-risk actions
5. **Centralized Dashboard**: Visualize all cross-account access in real-time
