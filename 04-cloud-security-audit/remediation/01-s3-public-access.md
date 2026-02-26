# Remediation Runbook: S3 Buckets Publicly Accessible

## Finding Details

**CIS Control:** 2.1.5  
**Severity:** CRITICAL  
**Risk Score:** 125  
**Category:** Data Exposure

## Description

One or more S3 buckets are configured to allow public access, potentially exposing sensitive data to the internet. This violates the principle of least privilege and creates a significant data breach risk.

## Business Impact

- **Data Breach:** Sensitive data could be accessed by unauthorized parties
- **Compliance Violation:** Fails PCI-DSS, HIPAA, GDPR requirements
- **Reputation Damage:** Public data exposure incidents harm brand trust
- **Financial Loss:** Potential fines, legal costs, and remediation expenses

## Risk Assessment

| Factor | Score | Justification |
|--------|-------|---------------|
| Severity | 5/5 | Data breach potential |
| Exploitability | 5/5 | Trivial - no authentication required |
| Exposure | 5/5 | Internet-facing |
| Mitigation | 1/5 | No compensating controls |
| **Total Risk** | **125** | **CRITICAL - Fix immediately** |

## Affected Resources

```
prod-data-bucket (us-east-1)
backup-bucket (us-west-2)
logs-bucket (eu-west-1)
```

## Remediation Steps

### Option 1: AWS Console

1. Navigate to S3 console
2. Select the affected bucket
3. Go to "Permissions" tab
4. Click "Block public access (bucket settings)"
5. Click "Edit"
6. Check all four options:
   - Block all public access
   - Block public access to buckets and objects granted through new access control lists (ACLs)
   - Block public access to buckets and objects granted through any access control lists (ACLs)
   - Block public access to buckets and objects granted through new public bucket or access point policies
7. Click "Save changes"
8. Type "confirm" and click "Confirm"

### Option 2: AWS CLI

```bash
# Block public access for a specific bucket
aws s3api put-public-access-block \
    --bucket prod-data-bucket \
    --public-access-block-configuration \
        "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# Verify the configuration
aws s3api get-public-access-block --bucket prod-data-bucket

# Remove any existing public ACLs
aws s3api put-bucket-acl --bucket prod-data-bucket --acl private
```

### Option 3: Terraform

```hcl
# Add to your Terraform configuration
resource "aws_s3_bucket_public_access_block" "prod_data" {
  bucket = aws_s3_bucket.prod_data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Apply the changes
# terraform plan
# terraform apply
```

### Option 4: CloudFormation

```yaml
Resources:
  S3BucketPublicAccessBlock:
    Type: AWS::S3::BucketPublicAccessBlock
    Properties:
      Bucket: !Ref ProdDataBucket
      BlockPublicAcls: true
      BlockPublicPolicy: true
      IgnorePublicAcls: true
      RestrictPublicBuckets: true
```

## Verification

### 1. Check Public Access Block Status

```bash
aws s3api get-public-access-block --bucket prod-data-bucket
```

Expected output:
```json
{
    "PublicAccessBlockConfiguration": {
        "BlockPublicAcls": true,
        "IgnorePublicAcls": true,
        "BlockPublicPolicy": true,
        "RestrictPublicBuckets": true
    }
}
```

### 2. Test Public Access

```bash
# Try to access bucket publicly (should fail)
curl https://prod-data-bucket.s3.amazonaws.com/
# Expected: Access Denied
```

### 3. Re-run Prowler Check

```bash
prowler aws --services s3 --check-id s3_bucket_public_access
```

## Prevention

### 1. Enable Account-Level Block Public Access

```bash
# Block public access for all buckets in the account
aws s3control put-public-access-block \
    --account-id 123456789012 \
    --public-access-block-configuration \
        "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
```

### 2. AWS Config Rule

```hcl
resource "aws_config_config_rule" "s3_bucket_public_read_prohibited" {
  name = "s3-bucket-public-read-prohibited"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
  }

  depends_on = [aws_config_configuration_recorder.main]
}
```

### 3. Service Control Policy (SCP)

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Action": [
        "s3:PutBucketPublicAccessBlock"
      ],
      "Resource": "*",
      "Condition": {
        "Bool": {
          "s3:BlockPublicAcls": "false",
          "s3:BlockPublicPolicy": "false"
        }
      }
    }
  ]
}
```

### 4. Automated Remediation with Lambda

```python
import boto3

def lambda_handler(event, context):
    """Auto-remediate public S3 buckets"""
    s3 = boto3.client('s3')
    bucket_name = event['detail']['requestParameters']['bucketName']
    
    # Block public access
    s3.put_public_access_block(
        Bucket=bucket_name,
        PublicAccessBlockConfiguration={
            'BlockPublicAcls': True,
            'IgnorePublicAcls': True,
            'BlockPublicPolicy': True,
            'RestrictPublicBuckets': True
        }
    )
    
    return {
        'statusCode': 200,
        'body': f'Blocked public access for bucket: {bucket_name}'
    }
```

## Rollback Plan

If legitimate public access is required:

1. Document business justification
2. Get security team approval
3. Implement least-privilege public access:
   ```bash
   # Allow public read for specific prefix only
   aws s3api put-bucket-policy --bucket prod-data-bucket --policy file://policy.json
   ```
4. Enable CloudTrail logging for bucket access
5. Set up CloudWatch alarms for unusual access patterns
6. Schedule quarterly review

## Timeline

- **Discovery:** 2024-01-15
- **Risk Assessment:** 2024-01-15
- **Remediation Target:** 2024-01-16 (24 hours)
- **Verification:** 2024-01-16
- **Status:** ⏳ In Progress

## References

- [CIS AWS Foundations Benchmark v1.5.0 - Section 2.1.5](https://www.cisecurity.org/benchmark/amazon_web_services)
- [AWS S3 Block Public Access](https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-control-block-public-access.html)
- [AWS Security Best Practices for S3](https://docs.aws.amazon.com/AmazonS3/latest/userguide/security-best-practices.html)

## Notes

- Coordinate with application teams before blocking public access
- Check if CloudFront or other services require bucket access
- Update application code if it relies on public bucket access
- Consider using pre-signed URLs for temporary public access needs
