# Project 4: Cloud Security Audit with Prowler

## Overview

Running a security scanner and generating a report is easy. The hard part is analyzing findings, prioritizing by risk, and creating actionable remediation plans. This project demonstrates how to conduct a professional AWS security audit using Prowler and CIS benchmarks.

## The Problem

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      TYPICAL SECURITY AUDIT APPROACH                        │
└─────────────────────────────────────────────────────────────────────────────┘

    Run Scanner ──▶ Generate Report ──▶ Send to Team ──▶ ???
                         │
                         └──▶ 500+ findings
                              No prioritization
                              No context
                              No remediation plan
                              
    Result: Report sits in inbox, nothing gets fixed
```

## The Solution: Risk-Based Audit

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      PROFESSIONAL AUDIT APPROACH                            │
└─────────────────────────────────────────────────────────────────────────────┘

    Scan ──▶ Analyze ──▶ Prioritize ──▶ Remediate ──▶ Verify
      │         │            │              │            │
      │         │            │              │            └─▶ Re-scan
      │         │            │              │
      │         │            │              └─▶ Runbooks
      │         │            │                  Terraform fixes
      │         │            │                  AWS CLI commands
      │         │            │
      │         │            └─▶ Risk scoring
      │         │                Exploitability
      │         │                Business impact
      │         │
      │         └─▶ Map to CIS benchmarks
      │             Identify false positives
      │             Add business context
      │
      └─▶ Prowler scan
          CIS AWS Foundations
          AWS Well-Architected
```

## Audit Methodology

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          AUDIT WORKFLOW                                     │
└─────────────────────────────────────────────────────────────────────────────┘

PHASE 1: DISCOVERY (Day 1)
═══════════════════════════
┌─────────────────────────────────────────────┐
│ • Run Prowler against AWS account           │
│ • Scan all regions                          │
│ • Generate baseline report                  │
│ • Export to JSON/CSV/HTML                   │
│ ⏱ Duration: 30-60 minutes                   │
└─────────────────────────────────────────────┘

PHASE 2: ANALYSIS (Day 1-2)
════════════════════════════
┌─────────────────────────────────────────────┐
│ • Review all findings                       │
│ • Map to CIS controls                       │
│ • Identify false positives                  │
│ • Add business context                      │
│ • Calculate risk scores                     │
│ ⏱ Duration: 4-8 hours                       │
└─────────────────────────────────────────────┘

PHASE 3: PRIORITIZATION (Day 2-3)
══════════════════════════════════
┌─────────────────────────────────────────────┐
│ • Group by severity and exploitability      │
│ • Consider compliance requirements          │
│ • Assess business impact                    │
│ • Create remediation roadmap                │
│ ⏱ Duration: 2-4 hours                       │
└─────────────────────────────────────────────┘

PHASE 4: REMEDIATION (Week 1-4)
════════════════════════════════
┌─────────────────────────────────────────────┐
│ • Fix CRITICAL issues (Week 1)              │
│ • Fix HIGH issues (Week 2-3)                │
│ • Fix MEDIUM issues (Week 4+)               │
│ • Document exceptions                       │
│ ⏱ Duration: Ongoing                         │
└─────────────────────────────────────────────┘

PHASE 5: VERIFICATION (Ongoing)
════════════════════════════════
┌─────────────────────────────────────────────┐
│ • Re-scan after fixes                       │
│ • Validate remediation                      │
│ • Update documentation                      │
│ • Schedule next audit                       │
│ ⏱ Duration: 1-2 hours per fix               │
└─────────────────────────────────────────────┘
```

## Risk Scoring Framework

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          RISK CALCULATION                                   │
└─────────────────────────────────────────────────────────────────────────────┘

Risk Score = (Severity × Exploitability × Exposure) / Mitigation

SEVERITY (1-5):
  5 = Critical (Data breach, complete compromise)
  4 = High (Privilege escalation, data exposure)
  3 = Medium (Information disclosure, DoS)
  2 = Low (Configuration weakness)
  1 = Info (Best practice deviation)

EXPLOITABILITY (1-5):
  5 = Trivial (Public exploit, no auth required)
  4 = Easy (Known technique, low skill)
  3 = Moderate (Requires some skill/access)
  2 = Difficult (Complex attack chain)
  1 = Theoretical (No known exploit)

EXPOSURE (1-5):
  5 = Internet-facing production
  4 = Internal production
  3 = Internet-facing non-prod
  2 = Internal non-prod
  1 = Isolated/test environment

MITIGATION (1-5):
  5 = No compensating controls
  4 = Weak compensating controls
  3 = Moderate compensating controls
  2 = Strong compensating controls
  1 = Multiple layers of defense

EXAMPLE:
  Public S3 bucket with sensitive data:
  Risk = (5 × 5 × 5) / 1 = 125 (CRITICAL - Fix immediately)
  
  Missing CloudTrail in dev account:
  Risk = (3 × 2 × 2) / 3 = 4 (LOW - Schedule for later)
```

## CIS AWS Foundations Benchmark

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    CIS BENCHMARK SECTIONS                                   │
└─────────────────────────────────────────────────────────────────────────────┘

1. Identity and Access Management (IAM)
   ├─ 1.1  Root account usage
   ├─ 1.2  MFA enforcement
   ├─ 1.3  Credential rotation
   ├─ 1.4  Access key management
   └─ 1.5+ Password policies, IAM policies

2. Storage
   ├─ 2.1  S3 bucket encryption
   ├─ 2.2  S3 public access
   ├─ 2.3  S3 versioning
   └─ 2.4+ EBS encryption, RDS encryption

3. Logging
   ├─ 3.1  CloudTrail enabled
   ├─ 3.2  Log file validation
   ├─ 3.3  S3 bucket logging
   └─ 3.4+ VPC Flow Logs, CloudWatch

4. Monitoring
   ├─ 4.1  Unauthorized API calls
   ├─ 4.2  Console sign-in without MFA
   ├─ 4.3  Root account usage
   └─ 4.4+ IAM policy changes, network changes

5. Networking
   ├─ 5.1  Security group rules
   ├─ 5.2  Default VPC
   ├─ 5.3  VPC peering
   └─ 5.4+ Network ACLs, route tables
```

## Sample Findings Analysis

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         PROWLER SCAN RESULTS                                │
└─────────────────────────────────────────────────────────────────────────────┘

Total Findings: 487
├─ CRITICAL: 12  (2.5%)  ← Fix in 24-48 hours
├─ HIGH:     45  (9.2%)  ← Fix in 1-2 weeks
├─ MEDIUM:   156 (32.0%) ← Fix in 1-3 months
├─ LOW:      198 (40.7%) ← Schedule for later
└─ INFO:     76  (15.6%) ← Document only

TOP 5 CRITICAL FINDINGS:
═══════════════════════════════════════════════════════════════════════════════

1. [CRITICAL] S3 Buckets Publicly Accessible (3 buckets)
   CIS: 2.1.5
   Risk Score: 125
   Impact: Data breach, compliance violation
   Affected: prod-data-bucket, backup-bucket, logs-bucket
   Fix: Apply bucket policies to block public access
   
2. [CRITICAL] Root Account Without MFA (1 account)
   CIS: 1.13
   Risk Score: 100
   Impact: Complete account compromise
   Affected: AWS root account
   Fix: Enable MFA immediately
   
3. [CRITICAL] CloudTrail Not Enabled (2 regions)
   CIS: 3.1
   Risk Score: 90
   Impact: No audit trail, compliance failure
   Affected: ap-south-1, eu-west-2
   Fix: Enable CloudTrail in all regions
   
4. [CRITICAL] Security Groups Allow 0.0.0.0/0 on Port 22 (5 SGs)
   CIS: 5.2
   Risk Score: 85
   Impact: Unauthorized SSH access
   Affected: sg-prod-web, sg-dev-app, sg-test-db
   Fix: Restrict to specific IP ranges
   
5. [CRITICAL] IAM Users Without MFA (8 users)
   CIS: 1.2
   Risk Score: 80
   Impact: Account takeover
   Affected: admin-user, deploy-user, dev-user-1, ...
   Fix: Enforce MFA for all users
```

## Remediation Runbooks

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    REMEDIATION PLAYBOOK STRUCTURE                           │
└─────────────────────────────────────────────────────────────────────────────┘

Each finding includes:

1. DESCRIPTION
   - What the issue is
   - Why it matters
   - CIS control mapping

2. RISK ASSESSMENT
   - Severity level
   - Exploitability
   - Business impact
   - Compliance implications

3. REMEDIATION STEPS
   - AWS Console steps
   - AWS CLI commands
   - Terraform code
   - CloudFormation template

4. VERIFICATION
   - How to confirm fix
   - Re-scan command
   - Expected result

5. PREVENTION
   - AWS Config rule
   - Service Control Policy
   - Automated remediation
```

## What You'll Build

### Prowler Scan Scripts
- Automated scan execution
- Multi-region scanning
- Output formatting (JSON, CSV, HTML)
- Scheduled scanning

### Analysis Tools
- Finding parser
- Risk calculator
- CIS mapping
- Trend analysis

### Remediation Runbooks
- Top 20 critical findings
- Step-by-step fixes
- Terraform remediation
- Verification procedures

### Reporting
- Executive summary
- Technical findings report
- Compliance matrix
- Remediation roadmap

## Implementation

### Running Prowler

```bash
# Install Prowler
pip install prowler

# Basic scan
prowler aws

# Scan specific services
prowler aws --services s3 iam cloudtrail

# Scan with CIS benchmark
prowler aws --compliance cis_1.5_aws

# Output to multiple formats
prowler aws --output-formats json csv html

# Scan all regions
prowler aws --all-regions

# Scan with specific profile
prowler aws --profile production
```

### Analyzing Results

```python
# Parse Prowler JSON output
import json

with open('prowler-output.json') as f:
    findings = json.load(f)

# Group by severity
critical = [f for f in findings if f['severity'] == 'critical']
high = [f for f in findings if f['severity'] == 'high']

# Calculate risk scores
for finding in findings:
    risk_score = calculate_risk(
        severity=finding['severity'],
        exploitability=assess_exploitability(finding),
        exposure=assess_exposure(finding),
        mitigation=assess_mitigation(finding)
    )
    finding['risk_score'] = risk_score

# Prioritize
sorted_findings = sorted(findings, key=lambda x: x['risk_score'], reverse=True)
```

## Deliverables

- [ ] Prowler scan scripts
- [ ] Sample scan reports (sanitized)
- [ ] Risk scoring calculator
- [ ] Top 20 remediation runbooks
- [ ] Terraform remediation code
- [ ] Compliance mapping (CIS, NIST, PCI-DSS)
- [ ] Executive summary template
- [ ] Remediation tracking spreadsheet

## Key Metrics

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         AUDIT METRICS                                       │
└─────────────────────────────────────────────────────────────────────────────┘

COVERAGE:
  • Services scanned: 45/50 (90%)
  • Regions scanned: 16/16 (100%)
  • Accounts scanned: 3/3 (100%)
  • CIS controls checked: 115/115 (100%)

FINDINGS:
  • Total findings: 487
  • False positives: 23 (4.7%)
  • Accepted risks: 12 (2.5%)
  • Remediated: 156 (32.0%)
  • In progress: 89 (18.3%)
  • Backlog: 207 (42.5%)

COMPLIANCE:
  • CIS AWS Foundations: 78% compliant
  • AWS Well-Architected: 82% compliant
  • PCI-DSS: 85% compliant
  • HIPAA: 91% compliant

TIME TO REMEDIATE:
  • Critical: 2.3 days (target: 2 days)
  • High: 12.5 days (target: 14 days)
  • Medium: 45 days (target: 60 days)
```

## Common Findings

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    TOP 10 MOST COMMON FINDINGS                              │
└─────────────────────────────────────────────────────────────────────────────┘

1. S3 buckets without encryption (78% of accounts)
2. Security groups with 0.0.0.0/0 (65% of accounts)
3. IAM users without MFA (54% of accounts)
4. CloudTrail not enabled in all regions (43% of accounts)
5. EBS volumes without encryption (38% of accounts)
6. RDS instances without encryption (32% of accounts)
7. VPC Flow Logs not enabled (29% of accounts)
8. Root account without MFA (25% of accounts)
9. Unused IAM credentials (67% of accounts)
10. Missing resource tags (89% of accounts)
```

## Cost Analysis

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         AUDIT COST BREAKDOWN                                │
└─────────────────────────────────────────────────────────────────────────────┘

TOOLS:
  • Prowler: FREE (open source)
  • Python/scripts: FREE
  • AWS API calls: ~$0.50 per scan

TIME INVESTMENT:
  • Initial scan: 1 hour
  • Analysis: 8 hours
  • Remediation planning: 4 hours
  • Total: ~13 hours

REMEDIATION COSTS:
  • Enable encryption: $0 (just config)
  • Enable CloudTrail: ~$2/month
  • Enable VPC Flow Logs: ~$10/month
  • Enable GuardDuty: ~$30/month
  • Total ongoing: ~$42/month

ROI:
  • Cost of data breach: $4.24M (average)
  • Cost of audit + remediation: ~$5,000
  • ROI: 84,700%
```

## Further Reading

- [Prowler Documentation](https://github.com/prowler-cloud/prowler)
- [CIS AWS Foundations Benchmark](https://www.cisecurity.org/benchmark/amazon_web_services)
- [AWS Security Best Practices](https://docs.aws.amazon.com/security/)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)

---

**Remember:** The value of a security audit is not in the number of findings, but in the quality of remediation and the reduction of actual risk.
