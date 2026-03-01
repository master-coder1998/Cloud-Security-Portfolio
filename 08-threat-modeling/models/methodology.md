# Threat Modeling Methodology

This document outlines the systematic approach used to perform threat modeling on the e-commerce platform.

---

## Process Overview

```
┌─────────────────────────────────────────────────────────────┐
│                  Threat Modeling Process                    │
└─────────────────────────────────────────────────────────────┘

Step 1: Define Scope
├── Identify system boundaries
├── List components and services
├── Define trust boundaries
└── Identify assets

Step 2: Create Architecture Diagram
├── Map data flows
├── Document entry points
├── Show trust boundaries
└── Identify external dependencies

Step 3: Identify Threats (STRIDE)
├── Spoofing threats
├── Tampering threats
├── Repudiation threats
├── Information Disclosure threats
├── Denial of Service threats
└── Elevation of Privilege threats

Step 4: Analyze Attack Paths
├── Map threat chains
├── Identify critical paths
├── Assess likelihood and impact
└── Calculate risk scores

Step 5: Map Controls
├── Identify existing controls
├── Map controls to threats
├── Identify control gaps
└── Prioritize remediation

Step 6: Document and Review
├── Create threat model documents
├── Review with stakeholders
├── Update as system evolves
└── Track remediation progress
```

---

## Step 1: Define Scope

### Questions to Answer

1. **What are we building?**
   - E-commerce platform with web and API tiers
   - Handles customer PII and payment data
   - Deployed on AWS using ECS, RDS, S3

2. **What are the system boundaries?**
   - External: Internet users, third-party APIs
   - Internal: AWS services, application components
   - Trust boundaries: Public/private subnets, data tier

3. **What assets are we protecting?**
   - Critical: Customer PII, payment data, credentials
   - High: Order history, product catalog
   - Medium: Application logs, metrics

4. **Who are the threat actors?**
   - External attackers (opportunistic, targeted)
   - Malicious insiders
   - Compromised supply chain
   - Nation-state actors (low likelihood)

---

## Step 2: Create Architecture Diagram

### Diagram Elements

1. **Components**: Boxes representing services
2. **Data Flows**: Arrows showing data movement
3. **Trust Boundaries**: Dashed lines separating trust zones
4. **Entry Points**: Where external data enters system
5. **Assets**: What data is stored where

### Best Practices

- Use consistent notation
- Show all external dependencies
- Clearly mark trust boundaries
- Include security controls (WAF, encryption)
- Keep diagrams up to date

---

## Step 3: Identify Threats (STRIDE)

### STRIDE Framework

#### Spoofing Identity
**Definition**: Pretending to be something or someone else

**Questions to Ask:**
- How do we authenticate users?
- Can an attacker impersonate a legitimate user?
- Are credentials properly protected?
- Can services spoof each other?

**Example Threats:**
- Session hijacking
- API key theft
- JWT token forgery
- Container image poisoning

---

#### Tampering with Data
**Definition**: Malicious modification of data

**Questions to Ask:**
- Can an attacker modify data in transit?
- Can an attacker modify data at rest?
- Are integrity checks in place?
- Can configuration be tampered with?

**Example Threats:**
- SQL injection
- Man-in-the-middle attacks
- S3 object modification
- Database tampering

---

#### Repudiation
**Definition**: Claiming not to have performed an action

**Questions to Ask:**
- Are all actions logged?
- Can logs be tampered with?
- Is there sufficient audit trail?
- Can users deny transactions?

**Example Threats:**
- Insufficient logging
- Log tampering
- Missing user context in logs
- CloudTrail disabled

---

#### Information Disclosure
**Definition**: Exposing information to unauthorized parties

**Questions to Ask:**
- What sensitive data exists?
- How is data protected at rest and in transit?
- Can error messages leak information?
- Are logs exposing sensitive data?

**Example Threats:**
- Credentials in logs
- Public S3 buckets
- Unencrypted databases
- Debug endpoints in production

---

#### Denial of Service
**Definition**: Denying or degrading service to legitimate users

**Questions to Ask:**
- What resources can be exhausted?
- Are there rate limits?
- Can expensive operations be triggered?
- Is there auto-scaling?

**Example Threats:**
- DDoS attacks
- Connection pool exhaustion
- Expensive database queries
- API rate limit bypass

---

#### Elevation of Privilege
**Definition**: Gaining unauthorized capabilities

**Questions to Ask:**
- Are access controls properly enforced?
- Can users access other users' data?
- Are IAM permissions least privilege?
- Can privileges be escalated?

**Example Threats:**
- Broken access control
- Excessive IAM permissions
- Container escape
- Privilege escalation via IAM

---

## Step 4: Analyze Attack Paths

### Attack Path Components

1. **Initial Access**: How attacker gains foothold
2. **Execution**: How attacker runs malicious code
3. **Persistence**: How attacker maintains access
4. **Privilege Escalation**: How attacker gains higher privileges
5. **Defense Evasion**: How attacker avoids detection
6. **Credential Access**: How attacker steals credentials
7. **Discovery**: How attacker learns about environment
8. **Lateral Movement**: How attacker moves through system
9. **Collection**: How attacker gathers data
10. **Exfiltration**: How attacker steals data
11. **Impact**: What damage attacker causes

### Risk Scoring

#### Likelihood Assessment
- **Low (1)**: Requires specialized knowledge, significant resources
- **Medium (2)**: Requires moderate skill, some resources
- **High (3)**: Easy to exploit, readily available tools

#### Impact Assessment
- **Low (1)**: Minimal business impact
- **Medium (2)**: Moderate business impact
- **High (3)**: Significant business impact
- **Critical (4)**: Severe business impact

#### Risk Calculation
```
Risk Score = Likelihood × Impact

1-2: Low Risk (monitor)
3-4: Medium Risk (plan remediation)
6: High Risk (remediate soon)
9-12: Critical Risk (remediate immediately)
```

---

## Step 5: Map Controls

### Control Types

1. **Preventive**: Stop threats before they occur
   - Examples: WAF, input validation, encryption

2. **Detective**: Identify threats when they occur
   - Examples: CloudTrail, GuardDuty, alarms

3. **Corrective**: Respond to and recover from threats
   - Examples: Backups, incident response, patching

4. **Deterrent**: Discourage threat actors
   - Examples: Legal warnings, security training

### Control Mapping Process

1. **Identify Existing Controls**: What's already in place?
2. **Map to Threats**: Which threats does each control address?
3. **Assess Effectiveness**: How well does control mitigate threat?
4. **Identify Gaps**: Which threats lack adequate controls?
5. **Prioritize**: Which gaps are highest risk?

### Control Effectiveness Criteria

- **High**: Prevents or detects threat reliably
- **Medium**: Reduces likelihood or impact significantly
- **Low**: Provides minimal protection

---

## Step 6: Document and Review

### Documentation Structure

1. **Executive Summary**: High-level findings for leadership
2. **Architecture Diagram**: Visual representation of system
3. **Threat Analysis**: Detailed STRIDE analysis
4. **Attack Paths**: Credible attack scenarios
5. **Control Mapping**: Threats mapped to controls
6. **Recommendations**: Prioritized remediation plan

### Review Process

1. **Technical Review**: Security team validates findings
2. **Architecture Review**: Architects confirm accuracy
3. **Business Review**: Leadership approves priorities
4. **Ongoing Updates**: Revisit quarterly or after major changes

---

## Threat Modeling Tools

### Recommended Tools

1. **Microsoft Threat Modeling Tool**: Free, STRIDE-based
2. **OWASP Threat Dragon**: Open source, web-based
3. **IriusRisk**: Commercial, automated threat modeling
4. **Draw.io**: For architecture diagrams
5. **Markdown**: For documentation (version control friendly)

### Tool Selection Criteria

- Supports STRIDE methodology
- Integrates with existing workflows
- Enables collaboration
- Produces actionable output
- Maintains version history

---

## Common Pitfalls

### 1. Scope Creep
**Problem**: Trying to model entire organization  
**Solution**: Start with single application or component

### 2. Analysis Paralysis
**Problem**: Identifying hundreds of theoretical threats  
**Solution**: Focus on credible, high-impact threats

### 3. One-Time Exercise
**Problem**: Threat model becomes outdated  
**Solution**: Integrate into SDLC, review regularly

### 4. No Actionable Output
**Problem**: Threats identified but not remediated  
**Solution**: Prioritize and assign owners

### 5. Lack of Business Context
**Problem**: Technical analysis without business impact  
**Solution**: Involve business stakeholders

---

## Integration with SDLC

### Design Phase
- Create initial threat model
- Identify security requirements
- Design security controls

### Development Phase
- Implement security controls
- Conduct security code reviews
- Perform SAST/DAST scanning

### Testing Phase
- Validate security controls
- Perform penetration testing
- Test incident response

### Deployment Phase
- Enable monitoring and logging
- Configure security services
- Document operational procedures

### Operations Phase
- Monitor for threats
- Respond to incidents
- Update threat model

---

## Metrics and KPIs

### Process Metrics
- Threat models completed per quarter
- Average time to complete threat model
- Percentage of projects with threat models

### Outcome Metrics
- Vulnerabilities identified pre-production
- Security incidents prevented
- Mean time to detect (MTTD)
- Mean time to respond (MTTR)

### Coverage Metrics
- Percentage of threats with controls
- Control effectiveness scores
- Remediation completion rate

---

## References

### Frameworks and Standards
- STRIDE (Microsoft)
- PASTA (Process for Attack Simulation and Threat Analysis)
- OCTAVE (Operationally Critical Threat, Asset, and Vulnerability Evaluation)
- MITRE ATT&CK Framework

### Books
- "Threat Modeling: Designing for Security" by Adam Shostack
- "Threat Modeling" by Izar Tarandach and Matthew J. Coles

### Online Resources
- OWASP Threat Modeling Cheat Sheet
- Microsoft SDL Threat Modeling
- NIST SP 800-154: Guide to Data-Centric System Threat Modeling

---

## Conclusion

Threat modeling is not a one-time activity but an ongoing process. The goal is not to identify every possible threat, but to:

1. Understand the system architecture
2. Identify credible, high-impact threats
3. Ensure adequate controls are in place
4. Prioritize security investments
5. Enable informed risk decisions

A good threat model helps security teams think like attackers and build defenses accordingly.
