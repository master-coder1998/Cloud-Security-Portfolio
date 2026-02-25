# AWS Security Policies for Terraform
# These policies enforce security best practices for AWS resources

package terraform

import future.keywords.contains
import future.keywords.if
import future.keywords.in

# Deny S3 buckets without encryption
deny[msg] {
    resource := input.planned_values.root_module.resources[_]
    resource.type == "aws_s3_bucket"
    not has_encryption(resource)
    
    msg := sprintf("S3 bucket '%s' must have encryption enabled", [resource.name])
}

# Deny S3 buckets that are publicly accessible
deny[msg] {
    resource := input.planned_values.root_module.resources[_]
    resource.type == "aws_s3_bucket_public_access_block"
    resource.values.block_public_acls == false
    
    msg := sprintf("S3 bucket '%s' must block public ACLs", [resource.name])
}

deny[msg] {
    resource := input.planned_values.root_module.resources[_]
    resource.type == "aws_s3_bucket_public_access_block"
    resource.values.block_public_policy == false
    
    msg := sprintf("S3 bucket '%s' must block public policies", [resource.name])
}

# Deny security groups with overly permissive ingress rules
deny[msg] {
    resource := input.planned_values.root_module.resources[_]
    resource.type == "aws_security_group"
    rule := resource.values.ingress[_]
    rule.cidr_blocks[_] == "0.0.0.0/0"
    rule.from_port == 22
    
    msg := sprintf("Security group '%s' allows SSH (port 22) from 0.0.0.0/0", [resource.name])
}

deny[msg] {
    resource := input.planned_values.root_module.resources[_]
    resource.type == "aws_security_group"
    rule := resource.values.ingress[_]
    rule.cidr_blocks[_] == "0.0.0.0/0"
    rule.from_port == 3389
    
    msg := sprintf("Security group '%s' allows RDP (port 3389) from 0.0.0.0/0", [resource.name])
}

# Deny IAM policies with wildcard actions
deny[msg] {
    resource := input.planned_values.root_module.resources[_]
    resource.type == "aws_iam_policy"
    policy := json.unmarshal(resource.values.policy)
    statement := policy.Statement[_]
    statement.Effect == "Allow"
    statement.Action[_] == "*"
    
    msg := sprintf("IAM policy '%s' grants wildcard (*) permissions", [resource.name])
}

# Deny IAM roles without MFA for assume role
deny[msg] {
    resource := input.planned_values.root_module.resources[_]
    resource.type == "aws_iam_role"
    policy := json.unmarshal(resource.values.assume_role_policy)
    statement := policy.Statement[_]
    not has_mfa_condition(statement)
    statement.Principal.AWS
    
    msg := sprintf("IAM role '%s' should require MFA for assume role", [resource.name])
}

# Deny RDS instances without encryption
deny[msg] {
    resource := input.planned_values.root_module.resources[_]
    resource.type == "aws_db_instance"
    resource.values.storage_encrypted == false
    
    msg := sprintf("RDS instance '%s' must have storage encryption enabled", [resource.name])
}

# Deny RDS instances that are publicly accessible
deny[msg] {
    resource := input.planned_values.root_module.resources[_]
    resource.type == "aws_db_instance"
    resource.values.publicly_accessible == true
    
    msg := sprintf("RDS instance '%s' must not be publicly accessible", [resource.name])
}

# Deny EBS volumes without encryption
deny[msg] {
    resource := input.planned_values.root_module.resources[_]
    resource.type == "aws_ebs_volume"
    resource.values.encrypted == false
    
    msg := sprintf("EBS volume '%s' must be encrypted", [resource.name])
}

# Deny CloudTrail without log file validation
deny[msg] {
    resource := input.planned_values.root_module.resources[_]
    resource.type == "aws_cloudtrail"
    resource.values.enable_log_file_validation == false
    
    msg := sprintf("CloudTrail '%s' must have log file validation enabled", [resource.name])
}

# Warn on resources without required tags
warn[msg] {
    resource := input.planned_values.root_module.resources[_]
    not has_required_tags(resource)
    
    msg := sprintf("Resource '%s' is missing required tags (Environment, Owner, Project)", [resource.address])
}

# Helper functions
has_encryption(resource) {
    resource.values.server_side_encryption_configuration
}

has_mfa_condition(statement) {
    statement.Condition["Bool"]["aws:MultiFactorAuthPresent"]
}

has_required_tags(resource) {
    resource.values.tags.Environment
    resource.values.tags.Owner
    resource.values.tags.Project
}

# Allow resources that pass all checks
allow {
    count(deny) == 0
}
