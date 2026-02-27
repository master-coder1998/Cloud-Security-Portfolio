# Centralized Logging — Architecture Notes

This document supplements the README with a concise description of the
components and deployment considerations for Project 5.

- Central log archive (S3) with versioning and SSE-KMS
- Organization CloudTrail delivering to the archive
- VPC Flow Logs forwarded to CloudWatch and optionally exported to S3
- Tamper-evidence via CloudTrail log file validation and digest chaining
- Access control: write access from workload accounts, read access to
  security team, explicit deny for deletes

Deployment notes:
- Object Lock (WORM) and MFA Delete require special bucket creation steps.
- Cross-account principals must be scoped with `aws:SourceAccount` and
  `aws:SourceArn` where applicable.
