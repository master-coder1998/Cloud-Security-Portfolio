# AWS Cloud Security Portfolio

**Ankita Dixit** | [GitHub](https://github.com/master-coder1998) | [LinkedIn](https://www.linkedin.com/in/ankita-dixit-8892b8185/)

A collection of hands-on AWS cloud security projects built to demonstrate practical, production-oriented security engineering skills. Each project is independently implemented, documented with architectural reasoning, and reflects real-world trade-offs rather than tutorial-level work.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        CLOUD SECURITY PORTFOLIO                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│   │   Identity  │  │   Network   │  │   DevSecOps │  │  Compliance │        │
│   │     & AM    │  │   Security  │  │             │  │   & Audit   │        │
│   └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘        │
│          │                │                │                │               │
│          ▼                ▼                ▼                ▼               │
│   ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│   │  Project 1  │  │  Project 2  │  │  Project 3  │  │  Project 4  │        │
│   │ Cross-Acct  │  │  VPC + IaC  │  │   CI/CD     │  │   Prowler   │        │
│   │    IAM      │  │             │  │  Security   │  │    Audit    │        │
│   └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘        │
│                                                                             │
│   ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│   │  Visibility │  │ Operations  │  │   Secrets   │  │   Threat    │        │
│   │  & Logging  │  │ & Recovery  │  │   Hygiene   │  │  Modeling   │        │
│   └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘        │
│          │                │                │                │               │
│          ▼                ▼                ▼                ▼               │
│   ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│   │  Project 5  │  │  Project 6  │  │  Project 7  │  │  Project 8  │        │
│   │ Centralized │  │ Break-Glass │  │  Secrets    │  │   Threat    │        │
│   │   Logging   │  │   Access    │  │ Management  │  │   Models    │        │
│   └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘        │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Why These Projects Matter

Cloud security roles increasingly require candidates to demonstrate not just familiarity with tools, but the ability to reason through architecture decisions, assess risk, and implement controls in realistic environments. Certifications and course completions tell part of the story. Hands-on, documented work tells the rest.

Each project here is built around a real-world scenario, implemented with Terraform, and documented with the reasoning behind every significant decision. The goal is not to show that steps were followed, but to demonstrate how a security engineer thinks when designing, building, and evaluating controls on AWS.

---

## Projects Overview

| # | Project | Domain | Key Skills |
|---|---------|--------|------------|
| 1 | [IAM Cross-Account Access](./01-iam-cross-account-access/) | Identity & Access Management | Multi-account architecture, least privilege, role assumption |
| 2 | [VPC Infrastructure as Code](./02-vpc-infrastructure-as-code/) | Network Security | Terraform, network segmentation, security groups, NACLs |
| 3 | [CI/CD Security Pipeline](./03-cicd-security-pipeline/) | DevSecOps | Shift-left security, policy as code, automated scanning |
| 4 | [Cloud Security Audit](./04-cloud-security-audit/) | Compliance & Governance | Prowler, CIS benchmarks, risk prioritization, remediation planning |
| 5 | [Centralized Logging](./05-centralized-logging/) | Visibility & Monitoring | CloudTrail, log immutability, S3 lifecycle policies, incident response |
| 6 | [Break-Glass Access](./06-break-glass-access/) | Operations & Recovery | Emergency access procedures, governance controls, audit trails |
| 7 | [Secrets Management](./07-secrets-management/) | Credential Hygiene | AWS Secrets Manager, rotation policies, blast radius reduction |
| 8 | [Threat Modeling](./08-threat-modeling/) | Risk Analysis | STRIDE methodology, attack path mapping, control mapping |

---

### 1. [IAM Cross-Account Access](./01-iam-cross-account-access/)
**Domain:** Identity & Access Management  
**Skills:** Multi-account architecture, least privilege, role assumption

IAM misconfiguration is consistently one of the top causes of AWS security incidents. This project builds a cross-account role assumption model from scratch, enforcing least privilege at every boundary. It covers the reasoning behind trust policies, when to use permission boundaries versus SCPs, and how to audit role usage effectively.

---

### 2. [VPC Infrastructure as Code](./02-vpc-infrastructure-as-code/)
**Domain:** Network Security  
**Skills:** Terraform, network segmentation, security groups, NACLs

Network design decisions made early are hard to undo at scale. This project provisions a production-style VPC with public, private, and isolated subnet tiers using Terraform. It addresses common mistakes like overly permissive security groups, flat network designs, and missing egress controls, and documents why each architectural choice was made.

---

### 3. [CI/CD Security Pipeline](./03-cicd-security-pipeline/)
**Domain:** DevSecOps  
**Skills:** Shift-left security, policy as code, automated scanning

Security checks that happen after deployment are too late. This project integrates static analysis, secrets detection, and policy-as-code validation directly into a GitHub Actions pipeline. It demonstrates how to fail builds on real risk without creating excessive noise that developers learn to ignore.

---

### 4. [Cloud Security Audit](./04-cloud-security-audit/)
**Domain:** Compliance & Governance  
**Skills:** Prowler, CIS benchmarks, risk prioritization, remediation planning

Running a security scanner and generating a report is the easy part. This project goes further by analyzing Prowler output against CIS AWS benchmarks, prioritizing findings by exploitability and blast radius, and producing structured remediation plans. The focus is on the judgment required to act on findings, not just identify them.

---

### 5. [Centralized Logging](./05-centralized-logging/)
**Domain:** Visibility & Monitoring  
**Skills:** CloudTrail, log immutability, S3 lifecycle policies, incident response

You cannot investigate what you did not log. This project establishes a centralized, tamper-resistant logging architecture across AWS services, covering CloudTrail, VPC Flow Logs, and S3 access logs. It also addresses log retention strategy, cross-account log aggregation, and how log architecture supports incident response.

---

### 6. [Break-Glass Access](./06-break-glass-access/)
**Domain:** Operations & Recovery  
**Skills:** Emergency access procedures, governance controls, audit trails

Every production environment needs a controlled way to grant elevated access in emergencies without creating standing privilege. This project designs and implements a break-glass access pattern with strict audit trails, automatic alerts on use, and a documented revocation process. It treats operational security as seriously as technical controls.

---

### 7. [Secrets Management](./07-secrets-management/)
**Domain:** Credential Hygiene  
**Skills:** AWS Secrets Manager, rotation policies, blast radius reduction

Hardcoded credentials and long-lived access keys are among the most exploited vulnerabilities in cloud environments. This project implements a secrets management architecture using AWS Secrets Manager, covering automatic rotation, application integration patterns, and how to scope access to minimize blast radius when a secret is compromised.

---

### 8. [Threat Modeling](./08-threat-modeling/)
**Domain:** Risk Analysis  
**Skills:** STRIDE methodology, attack path mapping, control mapping

Technical controls are only as good as the threat model behind them. This project applies the STRIDE framework to a realistic AWS workload, maps out credible attack paths, and traces each threat to the controls that mitigate it. It demonstrates the ability to think offensively in order to defend more effectively.

---

## Repository Structure

```
aws-cloud-security-portfolio/
├── README.md
├── 01-iam-cross-account-access/
│   ├── README.md                      # Architecture decisions and trade-offs
│   ├── terraform/                     # Infrastructure as code
│   └── docs/                          # Supporting documentation
├── 02-vpc-infrastructure-as-code/
│   ├── README.md
│   ├── terraform/
│   └── docs/
├── 03-cicd-security-pipeline/
│   ├── README.md
│   ├── .github/workflows/             # GitHub Actions pipeline configs
│   └── policies/                      # OPA / security policies
├── 04-cloud-security-audit/
│   ├── README.md
│   ├── reports/                       # Sample Prowler audit outputs
│   └── remediation/                   # Remediation runbooks
├── 05-centralized-logging/
│   ├── README.md
│   ├── terraform/
│   └── docs/
├── 06-break-glass-access/
│   ├── README.md
│   ├── terraform/
│   └── runbooks/                      # Step-by-step operational procedures
├── 07-secrets-management/
│   ├── README.md
│   ├── examples/                      # Secure vs insecure pattern comparisons
│   └── terraform/
└── 08-threat-modeling/
    ├── README.md
    ├── models/                        # Threat model documents
    └── diagrams/                      # Architecture and attack path diagrams
```

---

## Technical Scope

Each project covers the following dimensions:

- **Architecture** - why the design was chosen over alternatives
- **Implementation** - Terraform-based infrastructure with inline comments explaining intent
- **Security controls** - what threats each control mitigates and its limitations
- **Trade-offs** - cost, complexity, and operational overhead considerations
- **Gaps and improvements** - honest assessment of what production hardening would require

---

## How to Use This Repository

### Replicating a Project

1. Navigate to the project folder and read the `README.md` thoroughly before touching any code
2. Review the Terraform files and understand the resource relationships before applying
3. Deploy into a dedicated AWS account or sandbox environment
4. Document your own observations and any deviations from the original design

### Extending a Project

Each project `README.md` includes a section on known limitations and suggested extensions. These are intentional starting points for going deeper, not gaps to be ignored.

---

## Prerequisites

- AWS Account (free tier is sufficient for most projects)
- Terraform >= 1.0
- AWS CLI configured with appropriate credentials
- Git for version control
- Basic familiarity with IAM, VPC, and AWS core services

---

## License

MIT License. Free to use for learning and portfolio building with attribution.
