# Deployment Guide: Cross-Account IAM Access

## Prerequisites

- AWS CLI installed and configured
- Terraform >= 1.0 installed
- Access to at least 2 AWS accounts:
  - Security/Admin Account (where you'll assume roles FROM)
  - Workload Account (where roles will be created)
- MFA device configured for your IAM user

## Step 1: Prepare Configuration

1. **Generate External ID**
   ```bash
   # Generate a secure random External ID
   openssl rand -base64 32
   ```
   Save this value securely (e.g., in AWS Secrets Manager or password manager)

2. **Copy and configure terraform.tfvars**
   ```bash
   cd terraform/
   cp terraform.tfvars.example terraform.tfvars
   ```

3. **Edit terraform.tfvars** with your values:
   ```hcl
   aws_region          = "us-east-1"
   environment         = "production"
   security_account_id = "111111111111"  # Your security account ID
   external_id         = "paste-generated-external-id-here"
   cicd_role_arn       = "arn:aws:iam::111111111111:role/GitHubActionsRole"
   deployment_bucket   = "my-deployment-artifacts"
   
   allowed_source_ips = [
     "203.0.113.0/24"  # Your corporate VPN CIDR
   ]
   ```

## Step 2: Deploy to Workload Account

1. **Configure AWS credentials for workload account**
   ```bash
   export AWS_PROFILE=workload-account
   # OR
   export AWS_ACCESS_KEY_ID=...
   export AWS_SECRET_ACCESS_KEY=...
   ```

2. **Initialize Terraform**
   ```bash
   terraform init
   ```

3. **Review the plan**
   ```bash
   terraform plan
   ```
   
   Verify:
   - 3 IAM roles will be created
   - Trust policies reference correct account IDs
   - External ID is set correctly
   - MFA is required

4. **Apply the configuration**
   ```bash
   terraform apply
   ```

5. **Save the outputs**
   ```bash
   terraform output > ../outputs.txt
   ```

## Step 3: Configure Security Account

In the security account, create IAM policies that allow users to assume the roles.

1. **Create assume-role policy**
   
   Create file: `security-account-policy.json`
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": "sts:AssumeRole",
         "Resource": [
           "arn:aws:iam::222222222222:role/SecurityAuditRole",
           "arn:aws:iam::222222222222:role/IncidentResponseRole"
         ]
       }
     ]
   }
   ```

2. **Apply policy to security team group**
   ```bash
   aws iam create-policy \
     --policy-name CrossAccountAssumeRole \
     --policy-document file://security-account-policy.json
   
   aws iam attach-group-policy \
     --group-name SecurityTeam \
     --policy-arn arn:aws:iam::111111111111:policy/CrossAccountAssumeRole
   ```

## Step 4: Test Role Assumption

1. **Get your MFA device ARN**
   ```bash
   aws iam list-mfa-devices
   ```

2. **Assume the Security Audit Role**
   ```bash
   aws sts assume-role \
     --role-arn arn:aws:iam::222222222222:role/SecurityAuditRole \
     --role-session-name test-session \
     --external-id YOUR_EXTERNAL_ID \
     --serial-number arn:aws:iam::111111111111:mfa/your-user \
     --token-code 123456
   ```

3. **Export temporary credentials**
   ```bash
   export AWS_ACCESS_KEY_ID=...
   export AWS_SECRET_ACCESS_KEY=...
   export AWS_SESSION_TOKEN=...
   ```

4. **Test access**
   ```bash
   # Should work (read-only)
   aws ec2 describe-instances
   aws iam list-users
   
   # Should fail (no write access)
   aws ec2 terminate-instances --instance-ids i-1234567890abcdef0
   ```

## Step 5: Configure Monitoring

1. **Create SNS topic for alerts** (if not exists)
   ```bash
   aws sns create-topic --name cross-account-access-alerts
   
   aws sns subscribe \
     --topic-arn arn:aws:sns:us-east-1:222222222222:cross-account-access-alerts \
     --protocol email \
     --notification-endpoint security-team@example.com
   ```

2. **Update monitoring.tf** with SNS topic ARN
   ```hcl
   variable "sns_topic_arn" {
     default = "arn:aws:sns:us-east-1:222222222222:cross-account-access-alerts"
   }
   ```

3. **Apply monitoring configuration**
   ```bash
   terraform apply
   ```

4. **Test alerts**
   - Assume a role and verify you receive an alert
   - Try to assume a role without MFA (should fail and alert)

## Step 6: Document and Train

1. **Create role assumption guide for team**
   - Document which roles exist and their purposes
   - Provide example commands for role assumption
   - Explain when each role should be used

2. **Add to AWS CLI config** (optional, for convenience)
   
   Edit `~/.aws/config`:
   ```ini
   [profile workload-audit]
   role_arn = arn:aws:iam::222222222222:role/SecurityAuditRole
   source_profile = security-account
   external_id = YOUR_EXTERNAL_ID
   mfa_serial = arn:aws:iam::111111111111:mfa/your-user
   
   [profile workload-incident-response]
   role_arn = arn:aws:iam::222222222222:role/IncidentResponseRole
   source_profile = security-account
   external_id = YOUR_EXTERNAL_ID
   mfa_serial = arn:aws:iam::111111111111:mfa/your-user
   ```
   
   Then use with:
   ```bash
   aws ec2 describe-instances --profile workload-audit
   ```

## Troubleshooting

### "Access Denied" when assuming role

**Check:**
1. Is MFA token correct and not expired?
2. Is External ID correct?
3. Does your IAM user have permission to assume the role?
4. Is your IP address in the allowed list (for Incident Response Role)?

**Debug:**
```bash
# Check CloudTrail for the failed AssumeRole event
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=AssumeRole \
  --max-results 10
```

### "Session has expired"

Role sessions expire after 1 hour. Re-assume the role:
```bash
# Use the same assume-role command as before
```

### "MFA device not found"

Verify your MFA device ARN:
```bash
aws iam list-mfa-devices --user-name your-username
```

### Monitoring alerts not firing

1. Verify CloudTrail is enabled and logging to CloudWatch
2. Check metric filter patterns match your role ARNs
3. Verify SNS topic subscription is confirmed

## Security Checklist

Before going to production:

- [ ] External ID is unique and stored securely
- [ ] MFA is required for all sensitive roles
- [ ] IP restrictions are configured for Incident Response Role
- [ ] CloudWatch alarms are configured and tested
- [ ] SNS alerts are going to correct distribution list
- [ ] Trust policies reference correct account IDs
- [ ] IAM policies follow least privilege
- [ ] Session duration is appropriate (1 hour recommended)
- [ ] Team is trained on when to use each role
- [ ] Incident response runbook includes role assumption steps
- [ ] Quarterly access review is scheduled

## Maintenance

### Quarterly Tasks
- Review all role assumptions in CloudTrail
- Verify authorized users still need access
- Check for unused roles (consider removing)
- Rotate External ID
- Review and update IP allow lists

### When Adding New Accounts
1. Deploy roles using same Terraform code
2. Update security account policy to include new role ARNs
3. Test role assumption
4. Update documentation

### When Removing Access
1. Remove user from security team group
2. Verify user can no longer assume roles
3. Review CloudTrail for any recent activity by that user

## Cost Estimate

- IAM Roles: $0 (free)
- CloudWatch Alarms: ~$0.50/month (5 alarms × $0.10)
- CloudWatch Logs: ~$1-5/month (depends on volume)
- CloudTrail: $0 (assuming organization trail already exists)

**Total: ~$2-6/month**

## Next Steps

After successful deployment:

1. Deploy to additional accounts (dev, staging, etc.)
2. Implement automated role discovery and documentation
3. Consider AWS SSO for larger scale deployments
4. Integrate with ticketing system for access requests
5. Set up automated compliance reporting
