# Security Control Mapping

This document maps identified threats to specific security controls, showing how each control mitigates one or more threats.

---

## Control Categories

1. **Preventive** - Stop threats before they occur
2. **Detective** - Identify threats when they occur
3. **Corrective** - Respond to and recover from threats
4. **Deterrent** - Discourage threat actors

---

## Network Security Controls

### C-01: AWS WAF Rules
**Type:** Preventive  
**Implementation:** CloudFront + ALB

| Threat ID | Threat | Mitigation |
|-----------|--------|------------|
| T-02 | XSS injection | XSS rule set blocks malicious scripts |
| T-07 | SQL injection | SQL injection rule set blocks patterns |
| D-01 | DDoS attack | Rate-based rules limit request volume |
| D-02 | Layer 7 attack | Custom rules block application attacks |

**Effectiveness:** High  
**Cost:** $5-20/month  
**Limitations:** Requires tuning to avoid false positives

---

### C-02: Security Groups (Stateful Firewall)
**Type:** Preventive  
**Implementation:** VPC

| Threat ID | Threat | Mitigation |
|-----------|--------|------------|
| S-02 | Direct ALB access | Only CloudFront IPs allowed |
| E-01 | Container escape | Limits lateral movement |
| D-03 | Connection attacks | Limits allowed ports and protocols |

**Effectiveness:** High  
**Cost:** Free  
**Limitations:** Requires proper configuration, no Layer 7 inspection

---

### C-03: Network ACLs
**Type:** Preventive  
**Implementation:** VPC subnets

| Threat ID | Threat | Mitigation |
|-----------|--------|------------|
| D-03 | Slowloris attack | Stateless filtering adds defense layer |
| E-01 | Container escape | Subnet isolation limits blast radius |

**Effectiveness:** Medium  
**Cost:** Free  
**Limitations:** Stateless, requires careful rule ordering

---

### C-04: VPC Flow Logs
**Type:** Detective  
**Implementation:** VPC

| Threat ID | Threat | Mitigation |
|-----------|--------|------------|
| S-02 | Bypass CloudFront | Detects direct connections to ALB |
| E-01 | Container escape | Detects unusual network patterns |
| D-04 | Connection exhaustion | Identifies attack sources |

**Effectiveness:** Medium  
**Cost:** $0.50/GB  
**Limitations:** Delayed visibility (up to 15 minutes)

---

## Application Security Controls

### C-05: TLS/SSL Encryption
**Type:** Preventive  
**Implementation:** CloudFront, ALB, RDS

| Threat ID | Threat | Mitigation |
|-----------|--------|------------|
| T-01 | Man-in-the-middle | Encrypts data in transit |
| I-01 | Request data exposure | Prevents eavesdropping |
| S-04 | Certificate compromise | Requires valid certificate |

**Effectiveness:** High  
**Cost:** Free (AWS Certificate Manager)  
**Limitations:** Requires proper certificate management

---

### C-06: Input Validation
**Type:** Preventive  
**Implementation:** Application code

| Threat ID | Threat | Mitigation |
|-----------|--------|------------|
| T-02 | XSS injection | Sanitizes user input |
| T-07 | SQL injection | Validates and escapes input |
| T-08 | Parameter tampering | Validates parameter types and ranges |
| T-09 | Mass assignment | Whitelists allowed fields |

**Effectiveness:** High  
**Cost:** Development time  
**Limitations:** Requires comprehensive implementation

---

### C-07: Output Encoding
**Type:** Preventive  
**Implementation:** Application code

| Threat ID | Threat | Mitigation |
|-----------|--------|------------|
| T-02 | XSS injection | Encodes output to prevent script execution |
| I-02 | Error message disclosure | Sanitizes error responses |

**Effectiveness:** High  
**Cost:** Development time  
**Limitations:** Must be applied consistently

---

### C-08: API Rate Limiting
**Type:** Preventive  
**Implementation:** API Gateway, Application code

| Threat ID | Threat | Mitigation |
|-----------|--------|------------|
| D-05 | Rate limit bypass | Throttles requests per user/IP |
| D-06 | Expensive queries | Limits query frequency |
| I-06 | Data over-fetching | Prevents bulk data extraction |

**Effectiveness:** High  
**Cost:** Minimal  
**Limitations:** Can impact legitimate users if too aggressive

---

### C-09: Authentication (JWT)
**Type:** Preventive  
**Implementation:** Application code

| Threat ID | Threat | Mitigation |
|-----------|--------|------------|
| S-05 | Session hijacking | Validates token signature and expiry |
| S-07 | API key theft | Short-lived tokens limit exposure |
| S-08 | Token forgery | Cryptographic signing prevents forgery |

**Effectiveness:** High  
**Cost:** Development time  
**Limitations:** Requires secure key management

---

### C-10: Authorization (RBAC)
**Type:** Preventive  
**Implementation:** Application code

| Threat ID | Threat | Mitigation |
|-----------|--------|------------|
| E-03 | Broken access control | Enforces role-based permissions |
| I-07 | IDOR | Validates user owns requested resource |
| T-08 | Parameter tampering | Checks authorization before action |

**Effectiveness:** High  
**Cost:** Development time  
**Limitations:** Requires consistent enforcement

---

## Data Security Controls

### C-11: Encryption at Rest (KMS)
**Type:** Preventive  
**Implementation:** RDS, S3, EBS

| Threat ID | Threat | Mitigation |
|-----------|--------|------------|
| I-09 | RDS snapshot exposure | Encrypts database snapshots |
| I-10 | S3 data exposure | Encrypts S3 objects |
| I-11 | Unencrypted data | Protects data at rest |

**Effectiveness:** High  
**Cost:** $1/key + $0.03/10k requests  
**Limitations:** Doesn't protect against authorized access

---

### C-12: S3 Bucket Policies
**Type:** Preventive  
**Implementation:** S3

| Threat ID | Threat | Mitigation |
|-----------|--------|------------|
| I-10 | S3 misconfiguration | Enforces private access |
| T-11 | S3 object tampering | Restricts write permissions |
| T-12 | Backup deletion | Prevents unauthorized deletion |

**Effectiveness:** High  
**Cost:** Free  
**Limitations:** Requires careful policy design

---

### C-13: S3 Versioning + Object Lock
**Type:** Preventive + Corrective  
**Implementation:** S3

| Threat ID | Threat | Mitigation |
|-----------|--------|------------|
| T-11 | S3 object tampering | Maintains version history |
| T-12 | Backup deletion | Immutable backups |
| R-04 | Data change repudiation | Audit trail of changes |

**Effectiveness:** High  
**Cost:** Storage costs for versions  
**Limitations:** Increases storage costs

---

### C-14: RDS Automated Backups
**Type:** Corrective  
**Implementation:** RDS

| Threat ID | Threat | Mitigation |
|-----------|--------|------------|
| T-10 | Database tampering | Point-in-time recovery |
| T-12 | Backup deletion | Automated backup retention |
| D-07 | Database unavailability | Enables recovery |

**Effectiveness:** High  
**Cost:** Included in RDS pricing  
**Limitations:** Recovery time objective (RTO) of minutes to hours

---

### C-15: Database Parameter Groups
**Type:** Preventive  
**Implementation:** RDS

| Threat ID | Threat | Mitigation |
|-----------|--------|------------|
| T-07 | SQL injection | Enforces prepared statements |
| D-06 | Expensive queries | Query timeouts |
| E-05 | Excessive DB privileges | Restricts dangerous functions |

**Effectiveness:** Medium  
**Cost:** Free  
**Limitations:** Application must use properly

---

## Identity and Access Controls

### C-16: IAM Least Privilege Policies
**Type:** Preventive  
**Implementation:** IAM

| Threat ID | Threat | Mitigation |
|-----------|--------|------------|
| E-02 | Excessive IAM permissions | Grants minimum required permissions |
| E-04 | IAM role assumption | Limits role assumption scope |
| E-06 | Privilege escalation | Prevents policy manipulation |
| E-07 | Lambda overpermissive role | Scopes Lambda permissions |

**Effectiveness:** High  
**Cost:** Free  
**Limitations:** Requires ongoing maintenance

---

### C-17: IAM MFA Enforcement
**Type:** Preventive  
**Implementation:** IAM

| Threat ID | Threat | Mitigation |
|-----------|--------|------------|
| S-11 | IAM credential theft | Requires second factor |
| E-06 | Privilege escalation | Protects admin actions |

**Effectiveness:** High  
**Cost:** Free  
**Limitations:** User experience friction

---

### C-18: Secrets Manager
**Type:** Preventive  
**Implementation:** Secrets Manager

| Threat ID | Threat | Mitigation |
|-----------|--------|------------|
| S-09 | Database credential theft | Centralized secret storage |
| I-03 | Credentials in logs | Removes hardcoded credentials |
| I-14 | Secret exposure | Encrypted storage with access control |

**Effectiveness:** High  
**Cost:** $0.40/secret/month  
**Limitations:** Application must integrate properly

---

### C-19: Credential Rotation
**Type:** Preventive  
**Implementation:** Secrets Manager, IAM

| Threat ID | Threat | Mitigation |
|-----------|--------|------------|
| S-07 | API key theft | Limits credential lifetime |
| S-09 | Database credential theft | Automatic rotation |
| S-11 | IAM credential theft | Forces periodic renewal |

**Effectiveness:** High  
**Cost:** Minimal  
**Limitations:** Requires application support

---

### C-20: IMDSv2
**Type:** Preventive  
**Implementation:** EC2, ECS

| Threat ID | Threat | Mitigation |
|-----------|--------|------------|
| E-02 | Excessive IAM permissions | Prevents SSRF attacks on metadata |
| E-04 | IAM role assumption | Requires session token |

**Effectiveness:** High  
**Cost:** Free  
**Limitations:** Requires application update

---

## Monitoring and Detection Controls

### C-21: CloudTrail Logging
**Type:** Detective  
**Implementation:** CloudTrail

| Threat ID | Threat | Mitigation |
|-----------|--------|------------|
| R-01 | Transaction repudiation | Logs all API calls |
| R-02 | Admin action repudiation | Audit trail of changes |
| R-03 | API call repudiation | Logs with user context |
| R-04 | Database change repudiation | Logs RDS API calls |
| I-13 | CloudTrail disabled | Detects logging changes |
| T-13 | IAM policy tampering | Logs policy modifications |

**Effectiveness:** High  
**Cost:** $2/100k events  
**Limitations:** Doesn't prevent, only detects

---

### C-22: CloudWatch Alarms
**Type:** Detective  
**Implementation:** CloudWatch

| Threat ID | Threat | Mitigation |
|-----------|--------|------------|
| D-04 | Connection exhaustion | Alerts on high connection count |
| D-07 | Database exhaustion | Alerts on connection pool usage |
| E-02 | Excessive permissions | Alerts on IAM policy changes |
| I-13 | CloudTrail disabled | Alerts on logging changes |

**Effectiveness:** Medium  
**Cost:** $0.10/alarm  
**Limitations:** Reactive, not preventive

---

### C-23: GuardDuty
**Type:** Detective  
**Implementation:** GuardDuty

| Threat ID | Threat | Mitigation |
|-----------|--------|------------|
| S-11 | IAM credential theft | Detects credential misuse |
| E-01 | Container escape | Detects unusual behavior |
| E-06 | Privilege escalation | Detects suspicious API calls |
| D-01 | DDoS attack | Detects attack patterns |

**Effectiveness:** High  
**Cost:** $4.50/million events  
**Limitations:** Requires tuning, generates noise

---

### C-24: Application Logging
**Type:** Detective  
**Implementation:** Application code, CloudWatch Logs

| Threat ID | Threat | Mitigation |
|-----------|--------|------------|
| R-01 | Transaction repudiation | Logs user actions |
| I-03 | Credentials in logs | Detects (if properly configured) |
| T-08 | Parameter tampering | Logs validation failures |

**Effectiveness:** Medium  
**Cost:** $0.50/GB  
**Limitations:** Must avoid logging sensitive data

---

### C-25: Container Image Scanning
**Type:** Detective  
**Implementation:** ECR, CI/CD pipeline

| Threat ID | Threat | Mitigation |
|-----------|--------|------------|
| S-06 | Image poisoning | Scans for vulnerabilities |
| T-05 | Code modification | Detects malicious code |

**Effectiveness:** Medium  
**Cost:** Included in ECR  
**Limitations:** Only detects known vulnerabilities

---

## Operational Controls

### C-26: Incident Response Plan
**Type:** Corrective  
**Implementation:** Documentation, runbooks

| Threat ID | Threat | Mitigation |
|-----------|--------|------------|
| All | All threats | Defines response procedures |

**Effectiveness:** Medium  
**Cost:** Time investment  
**Limitations:** Requires regular testing

---

### C-27: Backup and Recovery
**Type:** Corrective  
**Implementation:** RDS, S3, cross-region replication

| Threat ID | Threat | Mitigation |
|-----------|--------|------------|
| T-10 | Database tampering | Enables restoration |
| T-11 | S3 tampering | Enables restoration |
| T-12 | Backup deletion | Cross-account backups |
| D-07 | Database unavailability | Enables recovery |

**Effectiveness:** High  
**Cost:** Storage + transfer costs  
**Limitations:** Recovery time objective

---

### C-28: Security Training
**Type:** Deterrent + Preventive  
**Implementation:** Training program

| Threat ID | Threat | Mitigation |
|-----------|--------|------------|
| S-11 | Credential theft | Reduces phishing success |
| S-06 | Image poisoning | Improves secure coding |
| I-03 | Credentials in logs | Educates developers |

**Effectiveness:** Medium  
**Cost:** Time + training platform  
**Limitations:** Human factor remains

---

## Control Coverage Matrix

### Coverage by Threat Category

| Category | Threats | Controls | Coverage |
|----------|---------|----------|----------|
| Spoofing | 12 | 8 | 67% |
| Tampering | 14 | 12 | 86% |
| Repudiation | 4 | 4 | 100% |
| Information Disclosure | 14 | 10 | 71% |
| Denial of Service | 8 | 7 | 88% |
| Elevation of Privilege | 7 | 7 | 100% |

### High-Risk Threats with Controls

| Threat ID | Threat | Risk | Primary Control | Secondary Control |
|-----------|--------|------|-----------------|-------------------|
| S-02 | Bypass CloudFront | High | C-02 (Security Groups) | C-04 (Flow Logs) |
| T-02 | XSS injection | High | C-01 (WAF) | C-06 (Input Validation) |
| D-01 | DDoS attack | High | C-01 (WAF) | AWS Shield |
| D-02 | Layer 7 attack | High | C-01 (WAF) | C-08 (Rate Limiting) |
| S-05 | Session hijacking | High | C-09 (JWT Auth) | C-05 (TLS) |
| T-06 | File inclusion | High | C-06 (Input Validation) | C-10 (Authorization) |
| I-03 | Credentials in logs | High | C-18 (Secrets Manager) | C-24 (Log Filtering) |
| I-04 | Debug endpoints | High | C-10 (Authorization) | C-21 (CloudTrail) |
| E-02 | Excessive IAM | High | C-16 (Least Privilege) | C-22 (Alarms) |
| S-07 | API key theft | High | C-19 (Rotation) | C-09 (Short-lived tokens) |

---

## Control Gaps

### Threats with Insufficient Controls

1. **I-04 (Debug endpoints in production)**
   - Gap: No automated detection
   - Recommendation: Implement API endpoint inventory and monitoring

2. **S-06 (Container image poisoning)**
   - Gap: No image signing enforcement
   - Recommendation: Implement Docker Content Trust

3. **E-01 (Container escape)**
   - Gap: No runtime security monitoring
   - Recommendation: Implement Falco or similar tool

4. **D-06 (Expensive queries)**
   - Gap: No query cost analysis
   - Recommendation: Implement query performance monitoring

---

## Control Implementation Priority

### Phase 1: Critical (Immediate)
1. C-16: IAM Least Privilege
2. C-01: WAF Rules
3. C-11: Encryption at Rest
4. C-21: CloudTrail Logging
5. C-18: Secrets Manager

### Phase 2: High (1-3 months)
6. C-09: JWT Authentication
7. C-10: RBAC Authorization
8. C-08: Rate Limiting
9. C-23: GuardDuty
10. C-13: S3 Versioning + Object Lock

### Phase 3: Medium (3-6 months)
11. C-19: Credential Rotation
12. C-25: Image Scanning
13. C-20: IMDSv2
14. C-27: Cross-region Backups
15. C-28: Security Training

---

## Control Effectiveness Measurement

### Metrics to Track

1. **Mean Time to Detect (MTTD)**: Time from threat occurrence to detection
2. **Mean Time to Respond (MTTR)**: Time from detection to containment
3. **False Positive Rate**: Percentage of alerts that are false positives
4. **Control Coverage**: Percentage of threats with mitigating controls
5. **Vulnerability Remediation Time**: Time from discovery to fix

### Success Criteria

- MTTD < 15 minutes for critical threats
- MTTR < 1 hour for critical threats
- False positive rate < 5%
- Control coverage > 90% for high-risk threats
- Vulnerability remediation < 30 days for critical, < 90 days for high
