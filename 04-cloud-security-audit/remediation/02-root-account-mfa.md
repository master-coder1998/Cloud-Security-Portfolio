# Remediation Runbook: Root Account Without MFA

## Finding Details

**CIS Control:** 1.13  
**Severity:** CRITICAL  
**Risk Score:** 100  
**Category:** Authentication & Access Control

## Description

The AWS root account does not have Multi-Factor Authentication (MFA) enabled. The root account has unrestricted access to all AWS resources and services. Without MFA, the account is vulnerable to credential compromise through phishing, password leaks, or brute force attacks.

## Business Impact

- **Complete Account Takeover:** Attacker gains full control of AWS account
- **Data Breach:** Access to all data across all services
- **Resource Hijacking:** Cryptocurrency mining, botnet deployment
- **Service Disruption:** Deletion of critical resources
- **Financial Loss:** Unauthorized resource usage, ransom demands
- **Compliance Failure:** Violates SOC 2, ISO 27001, PCI-DSS requirements

## Risk Assessment

| Factor | Score | Justification |
|--------|-------|---------------|
| Severity | 5/5 | Complete account compromise |
| Exploitability | 4/5 | Phishing attacks are common |
| Exposure | 5/5 | Internet-accessible login |
| Mitigation | 1/5 | No compensating controls |
| **Total Risk** | **100** | **CRITICAL - Fix immediately** |

## Affected Resources

```
AWS Account: 123456789012
Root User Email: admin@company.com
MFA Status: DISABLED ❌
```

## Remediation Steps

### Step 1: Enable MFA for Root Account

1. Sign in to AWS Console as root user
2. Click on account name (top right) → "Security credentials"
3. In the "Multi-factor authentication (MFA)" section, click "Assign MFA device"
4. Choose MFA device type:
   - **Virtual MFA** (Recommended): Google Authenticator, Authy, Microsoft Authenticator
   - **Hardware MFA**: YubiKey, Gemalto token
   - **U2F Security Key**: YubiKey, Titan Security Key

### Step 2: Configure Virtual MFA (Recommended)

1. Select "Virtual MFA device" and click "Continue"
2. Install authenticator app on your phone:
   - Google Authenticator (iOS/Android)
   - Authy (iOS/Android)
   - Microsoft Authenticator (iOS/Android)
3. Click "Show QR code"
4. Scan QR code with authenticator app
5. Enter two consecutive MFA codes from the app
6. Click "Assign MFA"
7. Save the QR code securely (for backup)

### Step 3: Test MFA

1. Sign out of AWS Console
2. Sign in again as root user
3. Enter password
4. Enter MFA code from authenticator app
5. Verify successful login

### AWS CLI Verification

```bash
# Check MFA status (requires root credentials)
aws iam get-account-summary | grep AccountMFAEnabled

# Expected output:
# "AccountMFAEnabled": 1
```

## Verification Checklist

- [ ] MFA device assigned to root account
- [ ] Successfully logged in with MFA
- [ ] MFA backup codes saved securely
- [ ] QR code saved in secure location
- [ ] Root account password is strong (20+ characters)
- [ ] Root account email is monitored
- [ ] Root account usage is logged in CloudTrail

## Prevention & Best Practices

### 1. Minimize Root Account Usage

```bash
# Create IAM admin user instead
aws iam create-user --user-name admin-user

# Attach AdministratorAccess policy
aws iam attach-user-policy \
    --user-name admin-user \
    --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

# Enable MFA for IAM user
aws iam enable-mfa-device \
    --user-name admin-user \
    --serial-number arn:aws:iam::123456789012:mfa/admin-user \
    --authentication-code-1 123456 \
    --authentication-code-2 789012
```

### 2. Set Up CloudWatch Alarm for Root Usage

```hcl
resource "aws_cloudwatch_log_metric_filter" "root_usage" {
  name           = "RootAccountUsage"
  log_group_name = "/aws/cloudtrail/organization"
  pattern        = "{ $.userIdentity.type = \"Root\" && $.userIdentity.invokedBy NOT EXISTS && $.eventType != \"AwsServiceEvent\" }"

  metric_transformation {
    name      = "RootAccountUsageCount"
    namespace = "CloudTrailMetrics"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "root_usage_alarm" {
  alarm_name          = "root-account-usage"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "RootAccountUsageCount"
  namespace           = "CloudTrailMetrics"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alert on root account usage"
  alarm_actions       = [aws_sns_topic.security_alerts.arn]
}
```

### 3. Implement AWS Organizations SCP

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Action": "*",
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "aws:PrincipalArn": "arn:aws:iam::*:root"
        }
      }
    }
  ]
}
```

### 4. Root Account Security Checklist

- [ ] MFA enabled (virtual or hardware)
- [ ] Strong password (20+ characters, random)
- [ ] Password stored in password manager
- [ ] MFA backup codes stored securely
- [ ] Root email monitored 24/7
- [ ] CloudWatch alarm for root usage
- [ ] Root account only used for:
  - Changing account settings
  - Closing the account
  - Restoring IAM user permissions
  - Changing AWS Support plan
  - Registering as a seller in Reserved Instance Marketplace

## Emergency Access Procedure

If MFA device is lost:

1. Go to AWS sign-in page
2. Click "Troubleshoot MFA"
3. Verify identity using:
   - Email verification
   - Phone verification
   - Credit card verification
4. Contact AWS Support if needed
5. Once access restored, immediately:
   - Assign new MFA device
   - Review CloudTrail logs
   - Rotate root password
   - Check for unauthorized changes

## Compliance Mapping

| Framework | Control | Requirement |
|-----------|---------|-------------|
| CIS AWS | 1.13 | Ensure MFA is enabled for root account |
| PCI-DSS | 8.3 | Multi-factor authentication for remote access |
| SOC 2 | CC6.1 | Logical access controls |
| ISO 27001 | A.9.4.2 | Secure log-on procedures |
| NIST 800-53 | IA-2(1) | Multi-factor authentication |

## Timeline

- **Discovery:** 2024-01-15 09:00 UTC
- **Risk Assessment:** 2024-01-15 09:30 UTC
- **Remediation Target:** 2024-01-15 12:00 UTC (3 hours)
- **Actual Remediation:** 2024-01-15 10:15 UTC
- **Verification:** 2024-01-15 10:30 UTC
- **Status:** ✅ COMPLETED

## References

- [CIS AWS Foundations Benchmark v1.5.0 - Section 1.13](https://www.cisecurity.org/benchmark/amazon_web_services)
- [AWS Root Account Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_root-user.html)
- [AWS MFA Documentation](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_mfa.html)
- [AWS Security Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)

## Notes

- **NEVER** share root credentials
- **NEVER** create access keys for root account
- **ALWAYS** use IAM users for day-to-day operations
- Store MFA backup codes in a secure, offline location
- Consider using hardware MFA for additional security
- Review root account activity monthly in CloudTrail
