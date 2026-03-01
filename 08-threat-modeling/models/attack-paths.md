# Attack Path Analysis

This document maps credible attack paths through the e-commerce platform, showing how an attacker could chain vulnerabilities to achieve specific objectives.

---

## Attack Path 1: Data Exfiltration via API Exploitation

### Objective
Steal customer PII and payment information from the database.

### Attack Chain

```
┌─────────────────────────────────────────────────────────────┐
│ Step 1: Reconnaissance                                      │
├─────────────────────────────────────────────────────────────┤
│ Attacker discovers API endpoints via:                       │
│ - Public documentation                                      │
│ - GraphQL introspection                                     │
│ - Fuzzing common paths                                      │
│                                                             │
│ Threat: I-08 (GraphQL introspection)                        │
└─────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ Step 2: Authentication Bypass                               │
├─────────────────────────────────────────────────────────────┤
│ Attacker exploits:                                          │
│ - Broken authentication (weak JWT validation)              │
│ - Session fixation                                          │
│ - Stolen API key from GitHub leak                          │
│                                                             │
│ Threat: S-07 (API key theft), T-04 (session fixation)      │
└─────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ Step 3: Authorization Bypass                                │
├─────────────────────────────────────────────────────────────┤
│ Attacker exploits:                                          │
│ - Insecure direct object reference (IDOR)                  │
│ - Missing function-level access control                    │
│ - Parameter tampering to access other users' data          │
│                                                             │
│ Threat: I-07 (IDOR), E-03 (broken access control)          │
└─────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ Step 4: Data Extraction                                     │
├─────────────────────────────────────────────────────────────┤
│ Attacker:                                                   │
│ - Iterates through user IDs (1-1000000)                    │
│ - Extracts PII via /api/users/{id} endpoint                │
│ - Bypasses rate limiting via distributed requests          │
│                                                             │
│ Threat: I-06 (over-fetching), D-05 (rate limit bypass)     │
└─────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ Result: 1M customer records exfiltrated                    │
└─────────────────────────────────────────────────────────────┘
```

### Mitigations Required
1. Disable GraphQL introspection in production
2. Implement strong JWT validation with short expiry
3. Enforce object-level authorization checks
4. Implement aggressive rate limiting per user/IP
5. Add anomaly detection for bulk data access

---

## Attack Path 2: Privilege Escalation to AWS Account Takeover

### Objective
Gain administrative access to the AWS account.

### Attack Chain

```
┌─────────────────────────────────────────────────────────────┐
│ Step 1: Initial Compromise                                  │
├─────────────────────────────────────────────────────────────┤
│ Attacker gains access via:                                  │
│ - Phishing attack on developer                              │
│ - Compromised CI/CD pipeline                                │
│ - Exposed AWS credentials in public GitHub repo             │
│                                                             │
│ Threat: S-11 (IAM credential theft)                         │
└─────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ Step 2: Container Compromise                                │
├─────────────────────────────────────────────────────────────┤
│ Attacker:                                                   │
│ - Deploys malicious container image                        │
│ - Exploits RCE vulnerability in application                │
│ - Gains shell access to ECS task                           │
│                                                             │
│ Threat: S-06 (image poisoning), T-05 (code modification)   │
└─────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ Step 3: IAM Role Extraction                                 │
├─────────────────────────────────────────────────────────────┤
│ Attacker:                                                   │
│ - Queries EC2 metadata service (169.254.169.254)           │
│ - Extracts temporary IAM credentials                       │
│ - Discovers overly permissive role                         │
│                                                             │
│ Threat: E-02 (excessive IAM permissions)                    │
└─────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ Step 4: Privilege Escalation                                │
├─────────────────────────────────────────────────────────────┤
│ Attacker uses IAM role to:                                  │
│ - Create new IAM user with admin policy                    │
│ - Attach AdministratorAccess to existing role              │
│ - Assume higher-privileged role                            │
│                                                             │
│ Threat: E-06 (IAM privilege escalation)                     │
└─────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ Step 5: Persistence                                         │
├─────────────────────────────────────────────────────────────┤
│ Attacker:                                                   │
│ - Creates backdoor IAM users                                │
│ - Disables CloudTrail logging                              │
│ - Modifies security group rules                            │
│                                                             │
│ Threat: I-13 (CloudTrail disabled), T-13 (policy tampering)│
└─────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ Result: Full AWS account compromise                         │
└─────────────────────────────────────────────────────────────┘
```

### Mitigations Required
1. Implement least privilege IAM policies
2. Use IMDSv2 to prevent SSRF attacks on metadata
3. Enable SCPs to prevent privilege escalation
4. Implement CloudTrail log file validation
5. Use AWS Config rules to detect policy changes
6. Enable GuardDuty for anomaly detection

---

## Attack Path 3: Ransomware via S3 and RDS Compromise

### Objective
Encrypt or delete critical data and demand ransom.

### Attack Chain

```
┌─────────────────────────────────────────────────────────────┐
│ Step 1: Credential Compromise                               │
├─────────────────────────────────────────────────────────────┤
│ Attacker obtains:                                           │
│ - Database credentials from Secrets Manager                 │
│ - S3 access via compromised IAM role                        │
│                                                             │
│ Threat: S-09 (credential theft), I-14 (Secrets Manager)    │
└─────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ Step 2: Data Exfiltration                                   │
├─────────────────────────────────────────────────────────────┤
│ Attacker:                                                   │
│ - Exports RDS database to S3                                │
│ - Downloads S3 objects to external storage                  │
│ - Copies data before encryption                             │
│                                                             │
│ Threat: I-10 (S3 misconfiguration)                          │
└─────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ Step 3: Data Destruction                                    │
├─────────────────────────────────────────────────────────────┤
│ Attacker:                                                   │
│ - Deletes all S3 objects (including versioned)             │
│ - Drops database tables                                     │
│ - Deletes RDS snapshots                                     │
│ - Deletes backups                                           │
│                                                             │
│ Threat: T-11 (S3 tampering), T-12 (backup deletion)        │
└─────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ Step 4: Ransom Demand                                       │
├─────────────────────────────────────────────────────────────┤
│ Attacker:                                                   │
│ - Leaves ransom note in S3 bucket                          │
│ - Demands payment for data return                          │
│ - Threatens to publish stolen data                         │
└─────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ Result: Business shutdown, data loss, ransom payment       │
└─────────────────────────────────────────────────────────────┘
```

### Mitigations Required
1. Enable S3 Object Lock for immutable backups
2. Enable S3 versioning with MFA delete
3. Implement cross-account backup replication
4. Enable RDS automated backups with retention
5. Use separate IAM roles for backup operations
6. Implement S3 bucket policies preventing deletion

---

## Attack Path 4: Supply Chain Attack via Container Image

### Objective
Inject malicious code into production via compromised container image.

### Attack Chain

```
┌─────────────────────────────────────────────────────────────┐
│ Step 1: Compromise Build Pipeline                           │
├─────────────────────────────────────────────────────────────┤
│ Attacker:                                                   │
│ - Compromises CI/CD credentials                            │
│ - Injects malicious code in build stage                    │
│ - Modifies Dockerfile to include backdoor                  │
│                                                             │
│ Threat: S-06 (container image poisoning)                    │
└─────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ Step 2: Image Deployment                                    │
├─────────────────────────────────────────────────────────────┤
│ Malicious image:                                            │
│ - Passes automated tests (backdoor dormant)                │
│ - Pushed to ECR                                             │
│ - Deployed to production ECS cluster                       │
└─────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ Step 3: Backdoor Activation                                 │
├─────────────────────────────────────────────────────────────┤
│ Backdoor:                                                   │
│ - Establishes reverse shell to attacker C2                 │
│ - Exfiltrates environment variables (secrets)              │
│ - Provides persistent access to container                  │
│                                                             │
│ Threat: I-03 (credentials in logs/env)                      │
└─────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ Step 4: Lateral Movement                                    │
├─────────────────────────────────────────────────────────────┤
│ Attacker:                                                   │
│ - Uses IAM role to access other services                   │
│ - Pivots to other containers in cluster                    │
│ - Accesses RDS and S3                                       │
│                                                             │
│ Threat: E-04 (IAM role assumption)                          │
└─────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ Result: Persistent access, data theft, infrastructure      │
│         compromise                                          │
└─────────────────────────────────────────────────────────────┘
```

### Mitigations Required
1. Implement image scanning in CI/CD (Trivy, Snyk)
2. Use ECR image scanning
3. Sign container images (Docker Content Trust)
4. Implement admission controllers (OPA)
5. Use read-only root filesystems
6. Implement network segmentation between containers
7. Monitor for unusual outbound connections

---

## Attack Path 5: DDoS Leading to Financial Loss

### Objective
Cause service outage and financial damage through resource exhaustion.

### Attack Chain

```
┌─────────────────────────────────────────────────────────────┐
│ Step 1: Reconnaissance                                      │
├─────────────────────────────────────────────────────────────┤
│ Attacker identifies:                                        │
│ - Expensive API endpoints (search, reports)                │
│ - Endpoints without rate limiting                          │
│ - Database-heavy operations                                │
└─────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ Step 2: Layer 7 Attack                                      │
├─────────────────────────────────────────────────────────────┤
│ Attacker:                                                   │
│ - Floods expensive endpoints with requests                 │
│ - Uses distributed botnet to bypass IP blocking           │
│ - Crafts queries that cause full table scans               │
│                                                             │
│ Threat: D-02 (Layer 7 attack), D-06 (expensive queries)    │
└─────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ Step 3: Resource Exhaustion                                 │
├─────────────────────────────────────────────────────────────┤
│ Impact:                                                     │
│ - Database connection pool exhausted                       │
│ - ECS tasks auto-scale to maximum                          │
│ - RDS CPU at 100%                                           │
│ - Redis memory full                                         │
│                                                             │
│ Threat: D-07 (connection exhaustion)                        │
└─────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ Step 4: Service Degradation                                 │
├─────────────────────────────────────────────────────────────┤
│ Result:                                                     │
│ - Legitimate users cannot access site                      │
│ - Transactions fail                                         │
│ - Revenue loss during outage                               │
│ - AWS bill increases 10x                                    │
└─────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ Result: Service outage, financial loss, reputation damage  │
└─────────────────────────────────────────────────────────────┘
```

### Mitigations Required
1. Enable AWS Shield Advanced
2. Implement WAF rate limiting rules
3. Add query complexity limits (GraphQL)
4. Implement database query timeouts
5. Use CloudFront with geo-blocking
6. Implement CAPTCHA for suspicious traffic
7. Set AWS budget alerts
8. Implement circuit breakers in application

---

## Attack Path Summary

| Path | Objective | Likelihood | Impact | Key Threats |
|------|-----------|------------|--------|-------------|
| 1 | Data Exfiltration | High | Critical | I-07, E-03, D-05 |
| 2 | Account Takeover | Medium | Critical | E-02, E-06, S-11 |
| 3 | Ransomware | Low | Critical | T-11, T-12, S-09 |
| 4 | Supply Chain | Medium | Critical | S-06, I-03, E-04 |
| 5 | DDoS | High | High | D-02, D-06, D-07 |

---

## Defense in Depth Strategy

To prevent these attack paths, implement controls at multiple layers:

### Layer 1: Perimeter (CloudFront, WAF, Route 53)
- DDoS protection
- Geographic restrictions
- Rate limiting
- Bot detection

### Layer 2: Network (VPC, Security Groups, NACLs)
- Network segmentation
- Least privilege network access
- VPC Flow Logs
- Private subnets for data tier

### Layer 3: Application (ECS, ALB)
- Input validation
- Output encoding
- Authentication and authorization
- Session management
- Error handling

### Layer 4: Data (RDS, S3, Secrets Manager)
- Encryption at rest and in transit
- Access logging
- Backup and recovery
- Data classification

### Layer 5: Identity (IAM, Secrets Manager)
- Least privilege
- MFA enforcement
- Credential rotation
- Audit logging

### Layer 6: Monitoring (CloudTrail, CloudWatch, GuardDuty)
- Real-time alerting
- Anomaly detection
- Incident response
- Forensics capability
