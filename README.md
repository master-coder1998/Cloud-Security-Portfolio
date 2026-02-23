# Cloud Security Portfolio

A collection of production-grade cloud security projects demonstrating real-world AWS security expertise. Each project includes working Terraform code, architectural documentation, and security best practices.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        CLOUD SECURITY PORTFOLIO                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐       │
│   │   Identity  │  │   Network   │  │   DevSecOps │  │  Compliance │       │
│   │     & IAM   │  │   Security  │  │             │  │   & Audit   │       │
│   └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘       │
│          │                │                │                │              │
│          ▼                ▼                ▼                ▼              │
│   ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐       │
│   │  Project 1  │  │  Project 2  │  │  Project 3  │  │  Project 4  │       │
│   │ Cross-Acct  │  │  VPC + IaC  │  │   CI/CD     │  │   Prowler   │       │
│   │    IAM      │  │             │  │  Security   │  │    Audit    │       │
│   └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘       │
│                                                                             │
│   ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐       │
│   │  Visibility │  │ Operations  │  │   Secrets   │  │   Threat    │       │
│   │  & Logging  │  │ & Recovery  │  │   Hygiene   │  │  Modeling   │       │
│   └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘       │
│          │                │                │                │              │
│          ▼                ▼                ▼                ▼              │
│   ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐       │
│   │  Project 5  │  │  Project 6  │  │  Project 7  │  │  Project 8  │       │
│   │ Centralized │  │ Break-Glass │  │  Secrets    │  │   Threat    │       │
│   │   Logging   │  │   Access    │  │ Management  │  │   Models    │       │
│   └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘       │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Projects

### ✅ 1. [IAM Cross-Account Access](./01-iam-cross-account-access/)
**Status:** Implemented  
**Domain:** Identity & Access Management  
**Skills:** Multi-account architecture, least privilege, role assumption, MFA enforcement

Production-ready cross-account IAM roles with MFA enforcement, External ID protection, and CloudWatch monitoring. Demonstrates proper trust policies, least privilege access, and security monitoring.

### 🔜 2. VPC Infrastructure as Code
**Domain:** Network Security  
**Skills:** Terraform, network segmentation, security groups, NACLs

### 🔜 3. CI/CD Security Pipeline
**Domain:** DevSecOps  
**Skills:** Shift-left security, policy as code, automated scanning

### 🔜 4. Cloud Security Audit
**Domain:** Compliance & Governance  
**Skills:** Prowler, CIS benchmarks, risk prioritization

### 🔜 5. Centralized Logging
**Domain:** Visibility & Monitoring  
**Skills:** CloudTrail, log immutability, incident response

### 🔜 6. Break-Glass Access
**Domain:** Operations & Recovery  
**Skills:** Emergency access procedures, governance controls

### 🔜 7. Secrets Management
**Domain:** Credential Hygiene  
**Skills:** AWS Secrets Manager, rotation policies

### 🔜 8. Threat Modeling
**Domain:** Risk Analysis  
**Skills:** STRIDE methodology, attack path mapping

## What Makes This Portfolio Different

- **Production-Ready Code**: Not tutorials - actual deployable infrastructure
- **Security Best Practices**: MFA, least privilege, monitoring, audit trails
- **Architectural Reasoning**: Every decision documented and explained
- **Real-World Thinking**: Trade-offs, scaling, incident response considerations

## Quick Start

```bash
# Clone the repository
git clone https://github.com/master-coder1998/Cloud-Security-Portfolio.git
cd Cloud-Security-Portfolio

# Navigate to a project
cd 01-iam-cross-account-access/terraform

# Deploy (after configuring terraform.tfvars)
terraform init
terraform plan
terraform apply
```

## Prerequisites

- AWS Account (free tier sufficient)
- Terraform >= 1.0
- AWS CLI configured
- Basic AWS knowledge

## License

MIT License - Free to use for learning and portfolio building.
