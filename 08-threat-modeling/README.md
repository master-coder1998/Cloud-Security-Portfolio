# Project 8: Threat Modeling

**Domain:** Risk Analysis  
**Skills:** STRIDE methodology, attack path mapping, control mapping, risk assessment

---

## Overview

Security controls are only as effective as the threat model behind them. Building defenses without understanding what you're defending against leads to wasted resources and false confidence. This project demonstrates systematic threat modeling using the STRIDE framework applied to a realistic e-commerce platform on AWS.

Rather than implementing infrastructure, this project focuses on the analytical process that should precede implementation: identifying threats, mapping attack paths, and ensuring controls address real risks. The deliverable is a comprehensive threat model that could guide security architecture decisions for a production system.

---

## Problem Statement

### Why Threat Modeling Matters

Most security breaches exploit predictable attack patterns:
- Credential theft leading to data exfiltration
- Privilege escalation from compromised containers
- Supply chain attacks via malicious dependencies
- DDoS attacks causing business disruption

These aren't novel attacks. They're well-documented and preventable. The problem isn't lack of security tools—it's lack of systematic thinking about how those tools map to actual threats.

### Common Failures

1. **Security Theater**: Implementing controls that don't address real threats
2. **Reactive Security**: Responding to incidents instead of preventing them
3. **Compliance-Driven**: Checking boxes without understanding risk
4. **Tool-Centric**: Buying products without threat context

---

## Methodology: STRIDE

STRIDE is a threat modeling framework that categorizes threats into six types:

```
┌─────────────────────────────────────────────────────────────┐
│                      STRIDE Framework                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  S - Spoofing          │  Impersonating users or systems   │
│  T - Tampering         │  Modifying data or code           │
│  R - Repudiation       │  Denying actions                  │
│  I - Info Disclosure   │  Exposing sensitive data          │
│  D - Denial of Service │  Degrading availability           │
│  E - Elevation of Priv │  Gaining unauthorized access      │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Why STRIDE?

- **Systematic**: Ensures comprehensive coverage
- **Repeatable**: Can be applied consistently across projects
- **Actionable**: Maps directly to security controls
- **Industry Standard**: Widely understood and documented

---

## Target System: E-Commerce Platform

### Architecture

```
Internet → CloudFront/WAF → ALB → Web Tier (ECS)
                                      ↓
                              Internal ALB → API Tier (ECS)
                                      ↓
                              RDS + Redis + S3
```

### Components
- **Frontend**: CloudFront, Route 53, Public ALB
- **Application**: ECS containers (web + API tiers)
- **Data**: RDS PostgreSQL, Redis, S3
- **Security**: WAF, Secrets Manager, KMS, CloudTrail

### Trust Boundaries
1. Internet → AWS (CloudFront/ALB)
2. Public Subnet → Private Subnet (Web → API)
3. Private Subnet → Data Subnet (API → Database)
4. Application → AWS Services (IAM, Secrets Manager)

See [diagrams/architecture.md](diagrams/architecture.md) for detailed architecture.

---

## Threat Analysis Results

### Summary Statistics

- **Total Threats Identified**: 59
- **High Risk**: 23 threats (39%)
- **Medium Risk**: 28 threats (47%)
- **Low Risk**: 8 threats (14%)

### Threats by Category

| Category | Count | Top Threat |
|----------|-------|------------|
| Spoofing | 12 | Session hijacking (S-05) |
| Tampering | 14 | SQL injection (T-07) |
| Repudiation | 4 | Insufficient logging (R-01) |
| Information Disclosure | 14 | Credentials in logs (I-03) |
| Denial of Service | 8 | DDoS attack (D-01) |
| Elevation of Privilege | 7 | Excessive IAM permissions (E-02) |

### Top 10 Critical Threats

1. **S-02**: Bypassing CloudFront to access ALB directly
2. **T-02**: XSS injection attacks
3. **D-01**: DDoS attack overwhelming CloudFront
4. **S-05**: Session hijacking via stolen tokens
5. **T-07**: SQL injection modifying database
6. **I-03**: Credentials exposed in application logs
7. **E-02**: Excessive IAM role permissions
8. **I-07**: Insecure direct object reference (IDOR)
9. **E-03**: Broken access control allowing privilege escalation
10. **S-07**: API key theft and reuse

See [models/stride-analysis.md](models/stride-analysis.md) for complete analysis.

---

## Attack Path Analysis

### Path 1: Data Exfiltration via API
**Objective**: Steal customer PII  
**Steps**: Reconnaissance → Auth bypass → IDOR exploitation → Bulk extraction  
**Likelihood**: High | **Impact**: Critical

### Path 2: AWS Account Takeover
**Objective**: Gain admin access  
**Steps**: Credential theft → Container compromise → IAM escalation → Persistence  
**Likelihood**: Medium | **Impact**: Critical

### Path 3: Ransomware Attack
**Objective**: Encrypt/delete data  
**Steps**: Credential compromise → Data exfiltration → Deletion → Ransom demand  
**Likelihood**: Low | **Impact**: Critical

### Path 4: Supply Chain Attack
**Objective**: Inject malicious code  
**Steps**: CI/CD compromise → Malicious image → Backdoor deployment → Lateral movement  
**Likelihood**: Medium | **Impact**: Critical

### Path 5: DDoS Attack
**Objective**: Cause outage  
**Steps**: Reconnaissance → Layer 7 attack → Resource exhaustion → Service degradation  
**Likelihood**: High | **Impact**: High

See [models/attack-paths.md](models/attack-paths.md) for detailed attack chains.

---

## Security Control Mapping

### Control Categories

- **Preventive**: 18 controls (WAF, encryption, IAM policies)
- **Detective**: 7 controls (CloudTrail, GuardDuty, alarms)
- **Corrective**: 3 controls (backups, incident response)
- **Deterrent**: 1 control (security training)

### Control Coverage

| Threat Category | Coverage |
|-----------------|----------|
| Spoofing | 67% |
| Tampering | 86% |
| Repudiation | 100% |
| Information Disclosure | 71% |
| Denial of Service | 88% |
| Elevation of Privilege | 100% |

### Key Controls

**C-01: AWS WAF** - Prevents XSS, SQL injection, DDoS  
**C-16: IAM Least Privilege** - Prevents privilege escalation  
**C-18: Secrets Manager** - Prevents credential exposure  
**C-21: CloudTrail** - Detects unauthorized actions  
**C-23: GuardDuty** - Detects anomalous behavior  

See [models/control-mapping.md](models/control-mapping.md) for complete mapping.

---

## Key Findings

### Strengths

1. **Defense in Depth**: Multiple layers of security controls
2. **Encryption**: Data protected at rest and in transit
3. **Monitoring**: Comprehensive logging and alerting
4. **Network Segmentation**: Clear trust boundaries

### Weaknesses

1. **IAM Permissions**: Risk of overly permissive roles
2. **Application Security**: Potential for injection attacks
3. **Access Control**: IDOR and broken authorization risks
4. **Supply Chain**: Limited container image validation

### Control Gaps

1. **No image signing enforcement** (Docker Content Trust)
2. **No runtime security monitoring** (Falco)
3. **No API endpoint inventory**
4. **No query cost analysis**

---

## Recommendations

### Immediate (Critical Risk)

1. **Implement IAM least privilege policies**
   - Review all IAM roles
   - Remove unnecessary permissions
   - Add SCPs to prevent escalation

2. **Enable WAF with managed rule sets**
   - Core rule set (XSS, SQL injection)
   - Rate-based rules
   - IP reputation lists

3. **Implement object-level authorization**
   - Validate user owns requested resource
   - Add authorization checks to all endpoints
   - Implement RBAC consistently

4. **Enable CloudTrail with log file validation**
   - Multi-region trail
   - Log file integrity validation
   - S3 bucket with Object Lock

5. **Deploy Secrets Manager**
   - Remove hardcoded credentials
   - Implement automatic rotation
   - Scope IAM access per secret

### Short-Term (High Risk)

6. Implement JWT authentication with short expiry
7. Add API rate limiting per user/IP
8. Enable GuardDuty for anomaly detection
9. Implement S3 versioning with Object Lock
10. Deploy container image scanning

### Medium-Term (Medium Risk)

11. Implement credential rotation
12. Enable IMDSv2 for metadata access
13. Deploy cross-region backups
14. Implement security training program
15. Add query performance monitoring

---

## Lessons Learned

### What Worked Well

- **Systematic approach**: STRIDE ensured comprehensive coverage
- **Attack path analysis**: Revealed threat chains not obvious from individual threats
- **Control mapping**: Identified specific gaps in defenses
- **Risk scoring**: Enabled prioritization of remediation

### Challenges

- **Scope management**: Easy to get lost in theoretical threats
- **Risk assessment**: Likelihood estimation requires domain knowledge
- **Control effectiveness**: Difficult to quantify without testing
- **Keeping current**: Threat landscape evolves constantly

### Best Practices

1. **Start with architecture diagram**: Visual representation is essential
2. **Focus on credible threats**: Don't chase theoretical risks
3. **Map to real controls**: Ensure threats have mitigations
4. **Involve stakeholders**: Get input from architects and developers
5. **Update regularly**: Threat model is living document

---

## Using This Threat Model

### For Security Teams

- Use as template for your own threat modeling
- Adapt STRIDE analysis to your architecture
- Customize attack paths for your threat actors
- Map to your existing security controls

### For Architects

- Reference when designing new systems
- Validate security controls address identified threats
- Use attack paths to test defense in depth
- Incorporate findings into architecture reviews

### For Developers

- Understand threats relevant to your code
- Implement controls at application layer
- Avoid common vulnerabilities (OWASP Top 10)
- Participate in threat modeling sessions

### For Leadership

- Understand risk landscape
- Prioritize security investments
- Make informed risk acceptance decisions
- Track remediation progress

---

## Threat Model Maintenance

### When to Update

- **Major architecture changes**: New services, components
- **New features**: Payment processing, user uploads
- **Security incidents**: Lessons learned
- **Quarterly reviews**: Ensure model stays current
- **Regulatory changes**: New compliance requirements

### Update Process

1. Review architecture for changes
2. Identify new threats
3. Update attack paths
4. Validate control effectiveness
5. Reprioritize remediation
6. Document changes

---

## Tools and Resources

### Threat Modeling Tools

- **Microsoft Threat Modeling Tool**: Free, STRIDE-based
- **OWASP Threat Dragon**: Open source, web-based
- **IriusRisk**: Commercial, automated
- **Draw.io**: Architecture diagrams

### Frameworks

- **STRIDE**: Microsoft threat categorization
- **PASTA**: Process for Attack Simulation and Threat Analysis
- **MITRE ATT&CK**: Adversary tactics and techniques
- **OWASP Top 10**: Common web application risks

### References

- [Microsoft SDL Threat Modeling](https://www.microsoft.com/en-us/securityengineering/sdl/threatmodeling)
- [OWASP Threat Modeling](https://owasp.org/www-community/Threat_Modeling)
- [NIST SP 800-154](https://csrc.nist.gov/publications/detail/sp/800-154/draft): Guide to Data-Centric Threat Modeling
- "Threat Modeling: Designing for Security" by Adam Shostack

---

## Project Structure

```
08-threat-modeling/
├── README.md                          # This file
├── models/
│   ├── stride-analysis.md             # Complete STRIDE threat analysis
│   ├── attack-paths.md                # Attack path mapping
│   ├── control-mapping.md             # Threats mapped to controls
│   └── methodology.md                 # Threat modeling process
└── diagrams/
    └── architecture.md                # System architecture diagram
```

---

## Conclusion

Threat modeling is not about achieving perfect security—that's impossible. It's about:

1. **Understanding your system**: What are you building?
2. **Identifying real threats**: What could go wrong?
3. **Prioritizing defenses**: What matters most?
4. **Making informed decisions**: What risks are acceptable?

This threat model demonstrates that security engineering is as much about analytical thinking as it is about technical implementation. The best security controls are those that address actual threats, not theoretical ones.

---

## License

MIT License - See repository root for details.
