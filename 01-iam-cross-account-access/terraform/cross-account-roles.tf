# Security Audit Role - Read-only access for security reviews
resource "aws_iam_role" "security_audit_role" {
  name               = "SecurityAuditRole"
  description        = "Cross-account role for security auditing with read-only access"
  assume_role_policy = data.aws_iam_policy_document.security_audit_trust.json
  max_session_duration = 3600

  tags = {
    Purpose = "SecurityAudit"
  }
}

data "aws_iam_policy_document" "security_audit_trust" {
  statement {
    effect = "Allow"
    
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.security_account_id}:root"]
    }
    
    actions = ["sts:AssumeRole"]
    
    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [var.external_id]
    }
    
    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["true"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "security_audit_managed" {
  role       = aws_iam_role.security_audit_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"
}

resource "aws_iam_role_policy_attachment" "security_audit_readonly" {
  role       = aws_iam_role.security_audit_role.name
  policy_arn = "arn:aws:iam::aws:policy/ViewOnlyAccess"
}

# Incident Response Role - Limited write access for incident handling
resource "aws_iam_role" "incident_response_role" {
  name               = "IncidentResponseRole"
  description        = "Cross-account role for incident response with limited write access"
  assume_role_policy = data.aws_iam_policy_document.incident_response_trust.json
  max_session_duration = 3600

  tags = {
    Purpose = "IncidentResponse"
  }
}

data "aws_iam_policy_document" "incident_response_trust" {
  statement {
    effect = "Allow"
    
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.security_account_id}:root"]
    }
    
    actions = ["sts:AssumeRole"]
    
    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [var.external_id]
    }
    
    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["true"]
    }
    
    condition {
      test     = "IpAddress"
      variable = "aws:SourceIp"
      values   = var.allowed_source_ips
    }
  }
}

resource "aws_iam_role_policy" "incident_response_policy" {
  name   = "IncidentResponsePolicy"
  role   = aws_iam_role.incident_response_role.id
  policy = data.aws_iam_policy_document.incident_response_permissions.json
}

data "aws_iam_policy_document" "incident_response_permissions" {
  # EC2 permissions for incident response
  statement {
    sid    = "EC2IncidentResponse"
    effect = "Allow"
    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeVolumes",
      "ec2:DescribeSnapshots",
      "ec2:CreateSnapshot",
      "ec2:CreateTags",
      "ec2:StopInstances",
      "ec2:ModifyInstanceAttribute"
    ]
    resources = ["*"]
  }

  # VPC permissions
  statement {
    sid    = "VPCIncidentResponse"
    effect = "Allow"
    actions = [
      "ec2:DescribeVpcs",
      "ec2:DescribeSubnets",
      "ec2:DescribeRouteTables",
      "ec2:DescribeNetworkAcls",
      "ec2:ModifyNetworkInterfaceAttribute",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupEgress"
    ]
    resources = ["*"]
  }

  # IAM read permissions
  statement {
    sid    = "IAMReadAccess"
    effect = "Allow"
    actions = [
      "iam:GetUser",
      "iam:GetRole",
      "iam:GetPolicy",
      "iam:ListUsers",
      "iam:ListRoles",
      "iam:ListPolicies",
      "iam:ListAccessKeys"
    ]
    resources = ["*"]
  }

  # CloudTrail read
  statement {
    sid    = "CloudTrailRead"
    effect = "Allow"
    actions = [
      "cloudtrail:LookupEvents",
      "cloudtrail:GetTrailStatus"
    ]
    resources = ["*"]
  }
}

# Deployment Role - For CI/CD pipelines
resource "aws_iam_role" "deployment_role" {
  name               = "DeploymentRole"
  description        = "Cross-account role for CI/CD deployments"
  assume_role_policy = data.aws_iam_policy_document.deployment_trust.json
  max_session_duration = 3600

  tags = {
    Purpose = "Deployment"
  }
}

data "aws_iam_policy_document" "deployment_trust" {
  statement {
    effect = "Allow"
    
    principals {
      type        = "AWS"
      identifiers = [var.cicd_role_arn]
    }
    
    actions = ["sts:AssumeRole"]
    
    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [var.external_id]
    }
  }
}

resource "aws_iam_role_policy" "deployment_policy" {
  name   = "DeploymentPolicy"
  role   = aws_iam_role.deployment_role.id
  policy = data.aws_iam_policy_document.deployment_permissions.json
}

data "aws_iam_policy_document" "deployment_permissions" {
  # ECS deployment permissions
  statement {
    sid    = "ECSDeployment"
    effect = "Allow"
    actions = [
      "ecs:UpdateService",
      "ecs:DescribeServices",
      "ecs:DescribeTaskDefinition",
      "ecs:RegisterTaskDefinition",
      "ecs:ListTasks",
      "ecs:DescribeTasks"
    ]
    resources = ["*"]
  }

  # ECR permissions
  statement {
    sid    = "ECRAccess"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload"
    ]
    resources = ["*"]
  }

  # S3 for deployment artifacts
  statement {
    sid    = "S3DeploymentArtifacts"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::${var.deployment_bucket}",
      "arn:aws:s3:::${var.deployment_bucket}/*"
    ]
  }
}
