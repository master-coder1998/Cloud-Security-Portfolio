# Project 5: Secure Logging and Centralised Visibility

**Ankita Dixit** | [GitHub](https://github.com/master-coder1998) | [LinkedIn](https://www.linkedin.com/in/ankita-dixit-8892b8185/)

## Overview

Many candidates say they "enabled logging." Very few show that they understand logging as an architectural problem. This project designs centralised logging properly—with immutability, access control, and tamper detection at its core.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                     CENTRALIZED LOGGING ARCHITECTURE                            │
└─────────────────────────────────────────────────────────────────────────────────┘

  WORKLOAD ACCOUNTS                          LOG ARCHIVE ACCOUNT
  ═════════════════                          ═══════════════════

┌─────────────────────┐                    ┌─────────────────────────────────────┐
│  Production Account │                    │                                     │
│  (111111111111)     │                    │         LOG ARCHIVE ACCOUNT         │
│                     │                    │         (999999999999)              │
│  ┌───────────────┐  │                    │                                     │
│  │  CloudTrail   │──┼───────────────────▶│  ┌─────────────────────────────┐    │
│  └───────────────┘  │                    │  │      S3 BUCKET               │    │
│  ┌───────────────┐  │                    │  │  (Central Log Archive)       │    │
│  │  VPC Flow Logs│──┼───────────────────▶│  │                              │    │
│  └───────────────┘  │                    │  │  ┌─────────────────────────┐ │    │
│  ┌───────────────┐  │                    │  │  │ • Object Lock (WORM)    │ │    │
│  │  Config Rules │──┼───────────────────▶│  │  │ • Versioning enabled    │ │    │
│  └───────────────┘  │                    │  │  │ • SSE-KMS encryption    │ │    │
└─────────────────────┘                    │  │  │ • Lifecycle policies    │ │    │
                                           │  │  │ • Cross-region replica  │ │    │
┌─────────────────────┐                    │  │  └─────────────────────────┘ │    │
│  Dev Account        │                    │  └─────────────────────────────┘    │
│  (222222222222)     │                    │                                     │
│                     │                    │  ┌─────────────────────────────┐    │
│  ┌───────────────┐  │                    │  │     ACCESS CONTROLS         │    │
│  │  CloudTrail   │──┼───────────────────▶│  │                             │    │
│  └───────────────┘  │                    │  │  • Write: Workload accounts │    │
│  ┌───────────────┐  │                    │  │  • Read: Security team only │    │
│  │  VPC Flow Logs│──┼───────────────────▶│  │  • Delete: NO ONE           │    │
│  └───────────────┘  │                    │  │  • Admin: Org management    │    │
└─────────────────────┘                    │  └─────────────────────────────┘    │
                                           │                                     │
┌─────────────────────┐                    │  ┌─────────────────────────────┐    │
│  Staging Account    │                    │  │     MONITORING              │    │
│  (333333333333)     │                    │  │                             │    │
│                     │                    │  │  • CloudWatch Alarms        │    │
│  ┌───────────────┐  │                    │  │  • Log delivery failures    │    │
│  │  CloudTrail   │──┼───────────────────▶│  │  • Unauthorized access      │    │
│  └───────────────┘  │                    │  │  • Deletion attempts        │    │
└─────────────────────┘                    │  └─────────────────────────────┘    │
                                           │                                     │
                                           └─────────────────────────────────────┘
```

## Log Flow and Protection

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                        LOG PROTECTION LAYERS                                    │
└─────────────────────────────────────────────────────────────────────────────────┘

                    ┌─────────────────────────────────────┐
                    │          LOG GENERATION             │
                    │   (CloudTrail, VPC, Application)    │
                    └──────────────────┬──────────────────┘
                                       │
                    ┌──────────────────▼──────────────────┐
         Layer 1:   │         IN-TRANSIT ENCRYPTION       │
                    │   (TLS 1.2+ to S3/CloudWatch)       │
                    └──────────────────┬──────────────────┘
                                       │
                    ┌──────────────────▼──────────────────┐
         Layer 2:   │         AT-REST ENCRYPTION          │
                    │   (SSE-KMS with CMK)                │
                    └──────────────────┬──────────────────┘
                                       │
                    ┌──────────────────▼──────────────────┐
         Layer 3:   │         IMMUTABILITY                │
                    │   (S3 Object Lock - Governance)     │
                    │   (Versioning + MFA Delete)         │
                    └──────────────────┬──────────────────┘
                                       │
                    ┌──────────────────▼──────────────────┐
         Layer 4:   │         ACCESS CONTROL              │
                    │   (Bucket Policy + IAM)             │
                    │   (No delete permissions)           │
                    └──────────────────┬──────────────────┘
                                       │
                    ┌──────────────────▼──────────────────┐
         Layer 5:   │         INTEGRITY VALIDATION        │
                    │   (CloudTrail log file validation)  │
                    │   (Hash chain verification)         │
                    └──────────────────┬──────────────────┘
                                       │
                    ┌──────────────────▼──────────────────┐
         Layer 6:   │         MONITORING                  │
                    │   (Alert on any anomaly)            │
                    └─────────────────────────────────────┘
```

## Why Logging Matters in Incidents

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                    ATTACKER vs DEFENDER: THE LOG BATTLE                         │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  ATTACKER'S FIRST MOVES:              DEFENDER'S COUNTERMEASURES:               │
│  ═══════════════════════              ═══════════════════════════               │
│                                                                                 │
│  1. Check if CloudTrail               1. Org-level trail can't be              │
│     is enabled                           disabled from member accounts         │
│                                                                                 │
│  2. Try to stop/delete                2. Logs go to separate account           │
│     CloudTrail                           attacker can't access                 │
│                                                                                 │
│  3. Delete log files                  3. Object Lock prevents deletion         │
│     from S3                                                                     │
│                                                                                 │
│  4. Modify log files                  4. Log validation detects                │
│     to hide activity                     tampering                             │
│                                                                                 │
│  5. Create admin user                 5. Immediately logged and                │
│     to maintain access                   alerted on                            │
│                                                                                 │
│                                                                                 │
│  ══════════════════════════════════════════════════════════════════════════    │
│  │  Without proper logging architecture:                                    │   │
│  │  Attacker wins - no evidence of what happened                            │   │
│  │                                                                          │   │
│  │  With this architecture:                                                 │   │
│  │  Full forensic trail preserved for investigation                         │   │
│  ══════════════════════════════════════════════════════════════════════════    │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## What to Log

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                         LOGGING REQUIREMENTS                                    │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │  CLOUDTRAIL (API Activity)                                              │   │
│  │  ─────────────────────────                                              │   │
│  │  • Management events (console, CLI, SDK)                                │   │
│  │  • Data events (S3 object access, Lambda invocations)                   │   │
│  │  • Insight events (unusual API patterns)                                │   │
│  │                                                                         │   │
│  │  Retention: 7 years (compliance) / 1 year (active analysis)             │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │  VPC FLOW LOGS (Network Traffic)                                        │   │
│  │  ───────────────────────────────                                        │   │
│  │  • Accepted/rejected traffic                                            │   │
│  │  • Source/destination IPs and ports                                     │   │
│  │  • Protocol and byte counts                                             │   │
│  │                                                                         │   │
│  │  Retention: 90 days (active) / 1 year (archive)                         │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │  AWS CONFIG (Configuration Changes)                                     │   │
│  │  ──────────────────────────────────                                     │   │
│  │  • Resource configuration snapshots                                     │   │
│  │  • Configuration change timeline                                        │   │
│  │  • Compliance rule evaluations                                          │   │
│  │                                                                         │   │
│  │  Retention: 7 years                                                     │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │  APPLICATION LOGS (Custom)                                              │   │
│  │  ─────────────────────────                                              │   │
│  │  • Authentication events                                                │   │
│  │  • Authorization decisions                                              │   │
│  │  • Data access patterns                                                 │   │
│  │  • Error conditions                                                     │   │
│  │                                                                         │   │
│  │  Retention: Based on sensitivity                                        │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## S3 Bucket Policy (Log Archive)

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                    LOG BUCKET POLICY DESIGN                                     │
└─────────────────────────────────────────────────────────────────────────────────┘

                    WHO CAN DO WHAT?
                    ════════════════

┌───────────────────────┬────────────┬────────────┬────────────┬─────────────────┐
│       Principal       │   Write    │    Read    │   Delete   │      Admin      │
├───────────────────────┼────────────┼────────────┼────────────┼─────────────────┤
│ CloudTrail Service    │     ✓      │     ✗      │     ✗      │       ✗         │
│ Workload Accounts     │     ✓      │     ✗      │     ✗      │       ✗         │
│ Security Team         │     ✗      │     ✓      │     ✗      │       ✗         │
│ SIEM Service          │     ✗      │     ✓      │     ✗      │       ✗         │
│ Org Management        │     ✗      │     ✓      │     ✗      │       ✓         │
│ EVERYONE ELSE         │     ✗      │     ✗      │     ✗      │       ✗         │
└───────────────────────┴────────────┴────────────┴────────────┴─────────────────┘

                    ║                                            ║
                    ║   DELETE is denied to EVERYONE             ║
                    ║   via explicit deny statement              ║
                    ║                                            ║
                    ╚════════════════════════════════════════════╝
```

## Tamper Detection

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                    CLOUDTRAIL LOG FILE VALIDATION                               │
└─────────────────────────────────────────────────────────────────────────────────┘

  Hour 1            Hour 2            Hour 3            Hour 4
    │                 │                 │                 │
    ▼                 ▼                 ▼                 ▼
┌────────┐       ┌────────┐       ┌────────┐       ┌────────┐
│ Log    │       │ Log    │       │ Log    │       │ Log    │
│ File 1 │       │ File 2 │       │ File 3 │       │ File 4 │
│        │       │        │       │        │       │        │
│ Hash:  │       │ Hash:  │       │ Hash:  │       │ Hash:  │
│ abc123 │◀──────│ prev:  │◀──────│ prev:  │◀──────│ prev:  │
└────────┘       │ abc123 │       │ def456 │       │ ghi789 │
                 │ curr:  │       │ curr:  │       │ curr:  │
                 │ def456 │       │ ghi789 │       │ jkl012 │
                 └────────┘       └────────┘       └────────┘
                      │
                      └──────────▶  Hash chain = Tamper evident

  DIGEST FILE (Hourly):
  ══════════════════════
  ┌─────────────────────────────────────────────────────────────────────────┐
  │  {                                                                      │
  │    "digestStartTime": "2026-01-14T10:00:00Z",                          │
  │    "digestEndTime": "2026-01-14T11:00:00Z",                            │
  │    "previousDigestSignature": "<signature>",                           │
  │    "logFiles": [                                                       │
  │      {                                                                 │
  │        "s3Bucket": "log-archive-bucket",                               │
  │        "s3Object": "AWSLogs/111.../2026/01/14/...",                    │
  │        "hashValue": "abc123def456...",                                 │
  │        "hashAlgorithm": "SHA-256"                                      │
  │      }                                                                 │
  │    ]                                                                   │
  │  }                                                                     │
  └─────────────────────────────────────────────────────────────────────────┘

  VALIDATION COMMAND:
  aws cloudtrail validate-logs --trail-arn <arn> --start-time <time>
```

## Monitoring and Alerting

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                    CRITICAL ALERTS TO CONFIGURE                                 │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  ┌──────────────────────────────────────────────────────────────────────────┐  │
│  │  LOGGING INFRASTRUCTURE ALERTS (Highest Priority)                        │  │
│  │  ─────────────────────────────────────────────────                       │  │
│  │  • CloudTrail stopped or deleted                    ──▶ P1 (Immediate)   │  │
│  │  • CloudTrail configuration changed                 ──▶ P1              │  │
│  │  • Log bucket policy modified                       ──▶ P1              │  │
│  │  • Log file validation failed                       ──▶ P1              │  │
│  │  • Log delivery failure                             ──▶ P2 (< 1 hour)   │  │
│  └──────────────────────────────────────────────────────────────────────────┘  │
│                                                                                 │
│  ┌──────────────────────────────────────────────────────────────────────────┐  │
│  │  SECURITY EVENT ALERTS (From Log Analysis)                               │  │
│  │  ─────────────────────────────────────────                               │  │
│  │  • Root account login                               ──▶ P1              │  │
│  │  • Console login without MFA                        ──▶ P2              │  │
│  │  • IAM policy changes                               ──▶ P2              │  │
│  │  • Security group changes                           ──▶ P2              │  │
│  │  • Network ACL changes                              ──▶ P2              │  │
│  │  • S3 bucket policy changes                         ──▶ P2              │  │
│  │  • Failed login attempts (> 5 in 10 min)            ──▶ P3 (< 4 hours)  │  │
│  └──────────────────────────────────────────────────────────────────────────┘  │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## Project Structure

```
05-centralized-logging/
├── README.md
├── terraform/
│   ├── main.tf                     # Provider config
│   ├── log-archive-bucket.tf       # S3 bucket with Object Lock
│   ├── cloudtrail.tf               # Organization trail
│   ├── vpc-flow-logs.tf            # Flow log configuration
│   ├── kms.tf                      # CMK for log encryption
│   ├── iam.tf                      # Cross-account roles
│   ├── cloudwatch-alarms.tf        # Monitoring configuration
│   └── variables.tf
└── docs/
    ├── architecture.md             # Detailed architecture
    ├── incident-response.md        # How to use logs in IR
    └── compliance-mapping.md       # Regulatory requirements
```

## Deliverables Checklist

- [ ] Centralized log bucket with Object Lock
- [ ] Organization CloudTrail configuration
- [ ] VPC Flow Logs to central location
- [ ] KMS key for log encryption
- [ ] Cross-account write access
- [ ] Restricted read access
- [ ] No delete access for anyone
- [ ] CloudWatch alarms for logging failures
- [ ] Log validation enabled
- [ ] Documentation of design decisions

## Questions to Answer in Your Documentation

1. **Why does log integrity matter?**
2. **What happens if logging is turned off?**
3. **How would you detect tampering?**
4. **Who should have access to logs?**
5. **How long should logs be retained?**
6. **What's the incident response playbook for logging alerts?**

## Further Reading

- [AWS CloudTrail Best Practices](https://docs.aws.amazon.com/awscloudtrail/latest/userguide/best-practices-security.html)
- [S3 Object Lock](https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lock.html)
- [CloudTrail Log File Validation](https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-log-file-validation-intro.html)

---

**Remember:** This demonstrates that you understand security from an incident response and forensics perspective, not just compliance. In real incidents, attackers often try to disable or erase logs first.
