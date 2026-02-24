# VPC Deployment Guide

## Prerequisites

- AWS Account
- Terraform >= 1.0
- AWS CLI configured
- Sufficient IAM permissions (VPC, EC2, CloudWatch, IAM)

## Quick Start

```bash
cd terraform/
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars
terraform init
terraform plan
terraform apply
```

## Configuration

### Basic Setup

```hcl
aws_region         = "us-east-1"
environment        = "production"
vpc_cidr           = "10.0.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b"]
```

### With Bastion Host

```hcl
enable_bastion = true
bastion_allowed_cidrs = ["203.0.113.0/24"]  # Your office IP
```

### With ECR Endpoints

```hcl
enable_ecr_endpoints = true  # Adds ~$14/month
```

## Deployment Steps

### 1. Initialize Terraform

```bash
terraform init
```

### 2. Review Plan

```bash
terraform plan
```

Expected resources: ~40-50 depending on configuration

### 3. Apply

```bash
terraform apply
```

Takes ~5-10 minutes (NAT Gateways are slow to create)

### 4. Verify

```bash
# Get VPC ID
terraform output vpc_id

# Check subnets
aws ec2 describe-subnets --filters "Name=vpc-id,Values=$(terraform output -raw vpc_id)"

# Verify Flow Logs
aws logs describe-log-groups --log-group-name-prefix "/aws/vpc/flow-logs"
```

## Testing Connectivity

### Test Public Subnet

```bash
# Launch instance in public subnet
aws ec2 run-instances \
  --image-id ami-xxxxx \
  --subnet-id $(terraform output -json public_subnet_ids | jq -r '.[0]') \
  --security-group-ids $(terraform output -raw alb_security_group_id)

# Should have public IP and internet access
```

### Test Private Subnet

```bash
# Launch instance in private subnet
aws ec2 run-instances \
  --image-id ami-xxxxx \
  --subnet-id $(terraform output -json private_subnet_ids | jq -r '.[0]') \
  --security-group-ids $(terraform output -raw app_security_group_id)

# Should have NO public IP but can reach internet via NAT
```

### Test Data Subnet

```bash
# Launch RDS in data subnet
# Should have NO internet access at all
```

## Troubleshooting

### NAT Gateway Not Working

**Check**:
1. Route table has 0.0.0.0/0 → NAT Gateway
2. NAT Gateway is in public subnet
3. NAT Gateway has Elastic IP
4. Security groups allow outbound traffic

### VPC Flow Logs Not Appearing

**Check**:
1. IAM role has correct permissions
2. CloudWatch log group exists
3. Wait 10-15 minutes (logs are delayed)

### Can't SSH to Bastion

**Check**:
1. `enable_bastion = true`
2. Your IP in `bastion_allowed_cidrs`
3. Bastion in public subnet
4. Security group allows port 22

## Cost Estimate

**Minimum (2 AZs)**:
- NAT Gateways: ~$64/month (2 × $32)
- VPC Flow Logs: ~$10-50/month (depends on traffic)
- **Total: ~$75-115/month**

**With ECR Endpoints**:
- Add ~$14/month per endpoint
- **Total: ~$103-143/month**

## Cleanup

```bash
# Destroy all resources
terraform destroy

# Verify nothing left
aws ec2 describe-vpcs --filters "Name=tag:Environment,Values=production"
```

## Next Steps

1. Deploy application resources (EC2, RDS, ALB)
2. Configure Route53 for DNS
3. Add WAF rules to ALB
4. Enable GuardDuty
5. Set up CloudWatch dashboards
