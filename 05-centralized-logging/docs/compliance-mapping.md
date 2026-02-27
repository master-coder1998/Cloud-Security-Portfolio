# Compliance Mapping

This file outlines how the centralized logging architecture maps to common
regulatory or standards requirements (e.g., PCI-DSS, SOC2, NIST).

- Retention: Satisfy retention requirements by lifecycle and cross-region replication
- Integrity: CloudTrail log file validation and S3 Object Lock support forensic requirements
- Access controls: fine-grained IAM + bucket policies to restrict read/delete
