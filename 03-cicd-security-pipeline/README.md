# Project 3: CI/CD Security Pipeline

## Overview

Security checks that happen after deployment are too late. This project demonstrates how to integrate security scanning directly into the CI/CD pipeline, failing builds on real risk without creating noise that developers ignore.

## The Problem

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        TRADITIONAL SECURITY APPROACH                        │
└─────────────────────────────────────────────────────────────────────────────┘

    Developer ──▶ Code ──▶ Build ──▶ Deploy ──▶ Production
                                                      │
                                                      ▼
                                              Security Scan
                                                      │
                                                      ▼
                                              Find Vulnerabilities
                                                      │
                                                      ▼
                                              Already in Production!
                                              Cost to fix: HIGH
                                              Risk window: DAYS/WEEKS
```

## The Solution: Shift-Left Security

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         SHIFT-LEFT SECURITY APPROACH                        │
└─────────────────────────────────────────────────────────────────────────────┘

    Developer ──▶ Code ──▶ Security Gate ──▶ Build ──▶ Deploy ──▶ Production
                              │
                              ├─▶ SAST Scan
                              ├─▶ Secrets Detection
                              ├─▶ Dependency Check
                              ├─▶ IaC Security
                              ├─▶ License Compliance
                              │
                              ▼
                          Pass/Fail Decision
                              │
                              ├─▶ PASS: Continue
                              └─▶ FAIL: Block deployment
                                        Cost to fix: LOW
                                        Risk window: ZERO
```

## Pipeline Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          SECURITY PIPELINE STAGES                           │
└─────────────────────────────────────────────────────────────────────────────┘

┌──────────────┐
│  Git Push    │
│  (Trigger)   │
└──────┬───────┘
       │
       ▼
┌──────────────────────────────────────────────────────────────────────────┐
│ STAGE 1: CODE QUALITY                                                    │
├──────────────────────────────────────────────────────────────────────────┤
│  • Linting (pylint, eslint)                                              │
│  • Code formatting (black, prettier)                                     │
│  • Complexity analysis                                                   │
│  ⏱ Duration: ~30 seconds                                                 │
└──────┬───────────────────────────────────────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────────────────────────────────────┐
│ STAGE 2: SECRETS DETECTION                                               │
├──────────────────────────────────────────────────────────────────────────┤
│  • Gitleaks (scan for hardcoded secrets)                                 │
│  • TruffleHog (entropy-based detection)                                  │
│  • Custom regex patterns                                                 │
│  ⏱ Duration: ~1 minute                                                   │
│  ❌ FAIL: If secrets found → Block deployment                            │
└──────┬───────────────────────────────────────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────────────────────────────────────┐
│ STAGE 3: STATIC APPLICATION SECURITY TESTING (SAST)                      │
├──────────────────────────────────────────────────────────────────────────┤
│  • Semgrep (multi-language SAST)                                         │
│  • Bandit (Python security)                                              │
│  • Checkov (IaC security)                                                │
│  ⏱ Duration: ~2-3 minutes                                                │
│  ❌ FAIL: If HIGH/CRITICAL findings → Block deployment                   │
└──────┬───────────────────────────────────────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────────────────────────────────────┐
│ STAGE 4: DEPENDENCY SCANNING (SCA)                                       │
├──────────────────────────────────────────────────────────────────────────┤
│  • Trivy (vulnerability scanner)                                         │
│  • OWASP Dependency-Check                                                │
│  • Snyk (optional)                                                       │
│  ⏱ Duration: ~2-4 minutes                                                │
│  ❌ FAIL: If critical CVEs → Block deployment                            │
└──────┬───────────────────────────────────────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────────────────────────────────────┐
│ STAGE 5: INFRASTRUCTURE AS CODE SECURITY                                 │
├──────────────────────────────────────────────────────────────────────────┤
│  • Checkov (Terraform/CloudFormation)                                    │
│  • tfsec (Terraform security)                                            │
│  • Custom OPA policies                                                   │
│  ⏱ Duration: ~1-2 minutes                                                │
│  ❌ FAIL: If policy violations → Block deployment                        │
└──────┬───────────────────────────────────────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────────────────────────────────────┐
│ STAGE 6: CONTAINER SECURITY (if applicable)                              │
├──────────────────────────────────────────────────────────────────────────┤
│  • Trivy image scan                                                      │
│  • Dockerfile best practices                                            │
│  • Base image validation                                                │
│  ⏱ Duration: ~2-3 minutes                                                │
└──────┬───────────────────────────────────────────────────────────────────┘
       │
       ▼
┌──────────────┐
│   ✅ PASS    │──▶ Continue to Build & Deploy
│   ❌ FAIL    │──▶ Block & Notify Developer
└──────────────┘
```

## What You'll Build

### GitHub Actions Workflows

1. **security-scan.yml** - Main security pipeline (includes IaC scanning)
2. **dependency-check.yml** - Daily dependency scanning

### Security Tools Integration

| Tool | Purpose | Severity Threshold |
|------|---------|-------------------|
| Gitleaks | Secrets detection | ANY secret = FAIL |
| Semgrep | SAST scanning | HIGH/CRITICAL = FAIL |
| Trivy | Dependency/Container scanning | CRITICAL CVE = FAIL |
| Checkov | IaC security | CRITICAL = FAIL |
| tfsec | Terraform security | HIGH/CRITICAL = FAIL |

### Policy as Code (OPA)

Custom policies for:
- IAM role trust policies
- S3 bucket encryption
- Security group rules
- Resource tagging

## Pipeline Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         DECISION TREE: FAIL vs WARN                         │
└─────────────────────────────────────────────────────────────────────────────┘

Finding Detected
       │
       ├─▶ Hardcoded Secret? ──────────────────────────▶ ❌ FAIL (Always)
       │
       ├─▶ Critical CVE with exploit? ────────────────▶ ❌ FAIL
       │
       ├─▶ High severity SAST finding? ───────────────▶ ❌ FAIL
       │
       ├─▶ Public S3 bucket in IaC? ──────────────────▶ ❌ FAIL
       │
       ├─▶ Security group 0.0.0.0/0? ─────────────────▶ ❌ FAIL
       │
       ├─▶ Medium severity with no fix? ──────────────▶ ⚠️  WARN (Continue)
       │
       ├─▶ Low severity finding? ─────────────────────▶ ⚠️  WARN (Continue)
       │
       └─▶ Info/Best practice? ───────────────────────▶ ℹ️  INFO (Continue)


FAIL = Block deployment, notify developer, create issue
WARN = Allow deployment, create tracking ticket
INFO = Log only, no action required
```

## Sample Findings Output

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         SECURITY SCAN RESULTS                               │
└─────────────────────────────────────────────────────────────────────────────┘

🔴 CRITICAL FINDINGS (2) - Deployment BLOCKED
───────────────────────────────────────────────────────────────────────────────
[SECRETS] Hardcoded AWS Access Key
  File: src/config.py:15
  Pattern: AKIA[0-9A-Z]{16}
  Action: Remove immediately, rotate credentials

[SAST] SQL Injection Vulnerability
  File: src/database.py:42
  Severity: HIGH
  CWE: CWE-89
  Fix: Use parameterized queries

🟡 WARNINGS (5) - Deployment ALLOWED
───────────────────────────────────────────────────────────────────────────────
[DEPENDENCY] lodash@4.17.15 - Prototype Pollution (CVE-2020-8203)
  Severity: MEDIUM
  Fix Available: Yes (upgrade to 4.17.21)
  Action: Schedule upgrade in next sprint

[IAC] S3 bucket versioning not enabled
  File: terraform/s3.tf:10
  Severity: MEDIUM
  Recommendation: Enable versioning for data protection

ℹ️  INFORMATIONAL (12) - No action required
───────────────────────────────────────────────────────────────────────────────
[CODE QUALITY] Function complexity exceeds threshold
[BEST PRACTICE] Missing resource tags
[STYLE] Line length exceeds 120 characters
```

## Implementation Details

### GitHub Actions Workflow Structure

```yaml
name: Security Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  secrets-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0  # Full history for secrets scan
      
      - name: Run Gitleaks
        uses: gitleaks/gitleaks-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

  sast-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Run Semgrep
        uses: returntocorp/semgrep-action@v1
        with:
          config: >-
            p/security-audit
            p/secrets
            p/owasp-top-ten

  dependency-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Run Trivy
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'fs'
          severity: 'CRITICAL,HIGH'
          exit-code: '1'  # Fail on findings

  iac-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Run Checkov
        uses: bridgecrewio/checkov-action@master
        with:
          directory: terraform/
          framework: terraform
          soft_fail: false  # Fail on critical findings
```

## Key Design Decisions

### Why These Tools?

**Gitleaks**: Fast, accurate, low false positives for secrets detection

**Semgrep**: Multi-language support, custom rules, fast scanning

**Trivy**: Comprehensive vulnerability database, container + filesystem scanning

**Checkov**: Best-in-class IaC security, supports multiple frameworks

### Fail vs Warn Strategy

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      SEVERITY THRESHOLD RATIONALE                           │
└─────────────────────────────────────────────────────────────────────────────┘

ALWAYS FAIL:
  • Hardcoded secrets (immediate security risk)
  • Critical CVEs with known exploits (active threat)
  • High severity SAST findings (exploitable vulnerabilities)
  • Public S3 buckets (data exposure risk)
  • Overly permissive security groups (attack surface)

WARN BUT ALLOW:
  • Medium severity with no active exploit
  • Dependency updates available but not critical
  • Best practice violations (non-security)
  • Code quality issues

RATIONALE:
  • Failing on everything creates "alert fatigue"
  • Developers will bypass security checks if too noisy
  • Focus on exploitable, high-impact issues
  • Track lower severity issues for future remediation
```

## Cost Analysis

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         PIPELINE COST BREAKDOWN                             │
└─────────────────────────────────────────────────────────────────────────────┘

GitHub Actions (Free Tier):
  • 2,000 minutes/month for private repos
  • Unlimited for public repos
  • Average pipeline run: ~10 minutes
  • Capacity: ~200 runs/month (free)

Tool Costs:
  • Gitleaks: FREE (open source)
  • Semgrep: FREE (community edition)
  • Trivy: FREE (open source)
  • Checkov: FREE (open source)
  • tfsec: FREE (open source)

Total Monthly Cost: $0 (using free tiers)

Paid Alternatives (Optional):
  • Snyk: $0-$99/month
  • SonarQube: $0-$150/month
  • GitHub Advanced Security: $49/user/month
```

## Metrics to Track

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         SECURITY METRICS DASHBOARD                          │
└─────────────────────────────────────────────────────────────────────────────┘

Pipeline Performance:
  • Average scan duration: 8 minutes
  • Success rate: 87%
  • False positive rate: <5%

Security Posture:
  • Critical findings blocked: 23 (last 30 days)
  • Secrets prevented from commit: 8
  • Vulnerable dependencies caught: 45
  • Mean time to remediation: 2.3 days

Developer Impact:
  • Pipeline failure rate: 13%
  • Time to fix blocked build: ~15 minutes
  • Developer satisfaction: 8.2/10
```

## Common Pitfalls

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         COMMON MISTAKES TO AVOID                            │
└─────────────────────────────────────────────────────────────────────────────┘

❌ Failing on every finding
   └─▶ Creates alert fatigue, developers bypass checks

❌ Running scans only on main branch
   └─▶ Issues found too late, harder to fix

❌ No clear remediation guidance
   └─▶ Developers don't know how to fix issues

❌ Scanning takes too long (>15 minutes)
   └─▶ Slows development, reduces adoption

❌ No exceptions process
   └─▶ Legitimate cases get blocked, workarounds created

✅ BEST PRACTICES:
   • Fail on critical/high only
   • Scan on every PR
   • Provide fix recommendations
   • Keep scans under 10 minutes
   • Document exception process
   • Track metrics and improve
```

## Deliverables

- [ ] GitHub Actions workflows for security scanning
- [ ] Gitleaks configuration for secrets detection
- [ ] Semgrep rules for SAST
- [ ] Trivy configuration for dependency scanning
- [ ] Checkov policies for IaC security
- [ ] Custom OPA policies for AWS resources
- [ ] Sample application with intentional vulnerabilities
- [ ] Documentation on fail/warn thresholds
- [ ] Metrics dashboard setup

## Further Reading

- [GitHub Actions Security Best Practices](https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions)
- [OWASP DevSecOps Guideline](https://owasp.org/www-project-devsecops-guideline/)
- [Semgrep Rules](https://semgrep.dev/explore)
- [Trivy Documentation](https://aquasecurity.github.io/trivy/)

---

**Remember:** The goal is not to catch every possible issue, but to prevent critical security risks from reaching production while maintaining developer velocity.
