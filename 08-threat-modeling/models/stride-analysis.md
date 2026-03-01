# STRIDE Threat Model: E-Commerce Platform

## Methodology

STRIDE is a threat modeling framework developed by Microsoft that categorizes threats into six types:

- **S**poofing - Impersonating something or someone
- **T**ampering - Modifying data or code
- **R**epudiation - Claiming not to have performed an action
- **I**nformation Disclosure - Exposing information to unauthorized parties
- **D**enial of Service - Denying or degrading service
- **E**levation of Privilege - Gaining unauthorized capabilities

---

## Threat Analysis by Component

### 1. CloudFront / WAF (Entry Point)

#### Spoofing
| Threat | Description | Likelihood | Impact | Risk |
|--------|-------------|------------|--------|------|
| S-01 | Attacker spoofs legitimate domain via DNS poisoning | Low | High | Medium |
| S-02 | Attacker bypasses CloudFront and accesses ALB directly | Medium | High | High |

#### Tampering
| Threat | Description | Likelihood | Impact | Risk |
|--------|-------------|------------|--------|------|
| T-01 | Man-in-the-middle attack modifies requests | Low | High | Medium |
| T-02 | Attacker injects malicious JavaScript via XSS | Medium | High | High |

#### Information Disclosure
| Threat | Description | Likelihood | Impact | Risk |
|--------|-------------|------------|--------|------|
| I-01 | CloudFront logs expose sensitive request data | Low | Medium | Low |
| I-02 | Error messages reveal system architecture | Medium | Low | Low |

#### Denial of Service
| Threat | Description | Likelihood | Impact | Risk |
|--------|-------------|------------|--------|------|
| D-01 | DDoS attack overwhelms CloudFront | High | High | High |
| D-02 | Layer 7 attack exhausts backend resources | Medium | High | High |

---

### 2. Application Load Balancer

#### Spoofing
| Threat | Description | Likelihood | Impact | Risk |
|--------|-------------|------------|--------|------|
| S-03 | Attacker spoofs X-Forwarded-For headers | Medium | Medium | Medium |
| S-04 | SSL/TLS certificate compromise | Low | Critical | Medium |

#### Tampering
| Threat | Description | Likelihood | Impact | Risk |
|--------|-------------|------------|--------|------|
| T-03 | Attacker modifies HTTP headers in transit | Low | Medium | Low |
| T-04 | Session fixation attack via cookie manipulation | Medium | High | High |

#### Denial of Service
| Threat | Description | Likelihood | Impact | Risk |
|--------|-------------|------------|--------|------|
| D-03 | Slowloris attack keeps connections open | Medium | Medium | Medium |
| D-04 | Connection exhaustion via rapid requests | High | High | High |

---

### 3. Web Tier (ECS Tasks)

#### Spoofing
| Threat | Description | Likelihood | Impact | Risk |
|--------|-------------|------------|--------|------|
| S-05 | Attacker impersonates legitimate user via stolen session | High | High | High |
| S-06 | Container image poisoning with malicious code | Low | Critical | Medium |

#### Tampering
| Threat | Description | Likelihood | Impact | Risk |
|--------|-------------|------------|--------|------|
| T-05 | Attacker modifies application code in running container | Low | Critical | Medium |
| T-06 | Local file inclusion vulnerability | Medium | High | High |

#### Repudiation
| Threat | Description | Likelihood | Impact | Risk |
|--------|-------------|------------|--------|------|
| R-01 | User denies performing transaction (insufficient logging) | Medium | Medium | Medium |
| R-02 | Admin actions not properly audited | Low | High | Medium |

#### Information Disclosure
| Threat | Description | Likelihood | Impact | Risk |
|--------|-------------|------------|--------|------|
| I-03 | Application logs contain PII or credentials | High | High | High |
| I-04 | Debug endpoints exposed in production | Medium | High | High |
| I-05 | Directory traversal exposes sensitive files | Low | High | Medium |

#### Elevation of Privilege
| Threat | Description | Likelihood | Impact | Risk |
|--------|-------------|------------|--------|------|
| E-01 | Container escape to host system | Low | Critical | Medium |
| E-02 | IAM role has excessive permissions | High | High | High |

---

### 4. API Tier (ECS Tasks)

#### Spoofing
| Threat | Description | Likelihood | Impact | Risk |
|--------|-------------|------------|--------|------|
| S-07 | API key theft and reuse | High | High | High |
| S-08 | JWT token forgery | Low | Critical | Medium |

#### Tampering
| Threat | Description | Likelihood | Impact | Risk |
|--------|-------------|------------|--------|------|
| T-07 | SQL injection modifies database | Medium | Critical | High |
| T-08 | API parameter tampering bypasses validation | High | High | High |
| T-09 | Mass assignment vulnerability | Medium | High | High |

#### Repudiation
| Threat | Description | Likelihood | Impact | Risk |
|--------|-------------|------------|--------|------|
| R-03 | API calls not logged with user context | Medium | Medium | Medium |

#### Information Disclosure
| Threat | Description | Likelihood | Impact | Risk |
|--------|-------------|------------|--------|------|
| I-06 | API returns excessive data (over-fetching) | High | Medium | Medium |
| I-07 | Insecure direct object reference exposes data | High | High | High |
| I-08 | GraphQL introspection reveals schema | Medium | Low | Low |

#### Denial of Service
| Threat | Description | Likelihood | Impact | Risk |
|--------|-------------|------------|--------|------|
| D-05 | API rate limiting bypass | High | Medium | Medium |
| D-06 | Resource exhaustion via expensive queries | Medium | High | High |

#### Elevation of Privilege
| Threat | Description | Likelihood | Impact | Risk |
|--------|-------------|------------|--------|------|
| E-03 | Broken access control allows privilege escalation | High | Critical | High |
| E-04 | IAM role assumption from compromised container | Medium | Critical | High |

---

### 5. Data Tier (RDS, Redis, S3)

#### Spoofing
| Threat | Description | Likelihood | Impact | Risk |
|--------|-------------|------------|--------|------|
| S-09 | Database credential theft from Secrets Manager | Medium | Critical | High |
| S-10 | Redis connection hijacking | Low | High | Medium |

#### Tampering
| Threat | Description | Likelihood | Impact | Risk |
|--------|-------------|------------|--------|------|
| T-10 | Direct database modification bypassing application | Low | Critical | Medium |
| T-11 | S3 object tampering via misconfigured permissions | Medium | High | High |
| T-12 | Backup tampering or deletion | Low | Critical | Medium |

#### Repudiation
| Threat | Description | Likelihood | Impact | Risk |
|--------|-------------|------------|--------|------|
| R-04 | Database changes not audited | Low | High | Medium |

#### Information Disclosure
| Threat | Description | Likelihood | Impact | Risk |
|--------|-------------|------------|--------|------|
| I-09 | RDS snapshot publicly accessible | Low | Critical | Medium |
| I-10 | S3 bucket misconfiguration exposes data | Medium | Critical | High |
| I-11 | Unencrypted data at rest | Low | Critical | Medium |
| I-12 | Redis cache poisoning exposes sensitive data | Medium | High | High |

#### Denial of Service
| Threat | Description | Likelihood | Impact | Risk |
|--------|-------------|------------|--------|------|
| D-07 | Database connection pool exhaustion | High | High | High |
| D-08 | S3 request throttling impacts availability | Low | Medium | Low |

#### Elevation of Privilege
| Threat | Description | Likelihood | Impact | Risk |
|--------|-------------|------------|--------|------|
| E-05 | Database user has excessive privileges | Medium | Critical | High |

---

### 6. Supporting Services (IAM, Secrets Manager, KMS)

#### Spoofing
| Threat | Description | Likelihood | Impact | Risk |
|--------|-------------|------------|--------|------|
| S-11 | IAM credential theft (access keys) | High | Critical | High |
| S-12 | Assume role from external account | Low | Critical | Medium |

#### Tampering
| Threat | Description | Likelihood | Impact | Risk |
|--------|-------------|------------|--------|------|
| T-13 | IAM policy modification by compromised admin | Low | Critical | Medium |
| T-14 | KMS key policy tampering | Low | Critical | Medium |

#### Information Disclosure
| Threat | Description | Likelihood | Impact | Risk |
|--------|-------------|------------|--------|------|
| I-13 | CloudTrail logs disabled or deleted | Medium | High | High |
| I-14 | Secrets Manager secret exposed via IAM misconfiguration | Medium | Critical | High |

#### Elevation of Privilege
| Threat | Description | Likelihood | Impact | Risk |
|--------|-------------|------------|--------|------|
| E-06 | IAM privilege escalation via policy manipulation | Medium | Critical | High |
| E-07 | Lambda function with overly permissive role | High | High | High |

---

## Risk Scoring

### Likelihood Scale
- **Low**: Requires significant effort, specialized knowledge, or unlikely conditions
- **Medium**: Possible with moderate effort and common tools
- **High**: Easy to exploit with readily available tools or common misconfigurations

### Impact Scale
- **Low**: Minimal business impact, limited data exposure
- **Medium**: Moderate business impact, some data exposure
- **High**: Significant business impact, substantial data exposure
- **Critical**: Severe business impact, complete system compromise

### Risk Matrix
```
                Impact
           Low  Med  High  Crit
        ┌─────┬────┬─────┬─────┐
    Low │  L  │ L  │  M  │  M  │
        ├─────┼────┼─────┼─────┤
    Med │  L  │ M  │  H  │  H  │
        ├─────┼────┼─────┼─────┤
   High │  M  │ H  │  H  │  C  │
        └─────┴────┴─────┴─────┘
Likelihood

L = Low Risk
M = Medium Risk
H = High Risk
C = Critical Risk
```

---

## Summary Statistics

### Threats by Category
- Spoofing: 12 threats
- Tampering: 14 threats
- Repudiation: 4 threats
- Information Disclosure: 14 threats
- Denial of Service: 8 threats
- Elevation of Privilege: 7 threats

**Total: 59 identified threats**

### Threats by Risk Level
- Critical: 0 threats
- High: 23 threats (39%)
- Medium: 28 threats (47%)
- Low: 8 threats (14%)

### Top 10 Critical Threats (High Risk + High/Critical Impact)

1. **S-02**: Bypassing CloudFront to access ALB directly
2. **T-02**: XSS injection attacks
3. **D-01**: DDoS attack on CloudFront
4. **D-02**: Layer 7 application attacks
5. **S-05**: Session hijacking
6. **T-06**: Local file inclusion
7. **I-03**: Credentials in application logs
8. **I-04**: Debug endpoints in production
9. **E-02**: Excessive IAM permissions
10. **S-07**: API key theft

These threats require immediate attention and mitigation controls.
