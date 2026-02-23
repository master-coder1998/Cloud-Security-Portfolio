# Project 1: IAM Cross-Account Access

## Overview

IAM misconfiguration is one of the leading causes of AWS security incidents. In real organisations, environments are multi-account by design — and managing access across those accounts securely requires more than just creating roles. This project implements a cross-account access model from scratch, documenting every architectural decision, the threats each control addresses, and where the implementation falls short of full production hardening.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         AWS ORGANIZATION                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌────────────────────────────┐      ┌────────────────────────────┐         │
│  │   SECURITY/ADMIN ACCOUNT   │      │    WORKLOAD ACCOUNT        │         │
│  │   (Account: 111111111111)  │      │   (Account: 222222222222)  │         │
│  │                            │      │                            │         │
│  │  ┌──────────────────────┐  │      │  ┌──────────────────────┐  │         │
│  │  │   IAM User/Role      │  │      │  │  Cross-Account Role  │  │         │
│  │  │   "SecurityAdmin"    │──┼──────┼─▶│  "SecurityAuditRole" │  │         │
│  │  │                      │  │ STS  │  │                      │  │         │
│  │  │  ┌────────────────┐  │  │Assume│  │  ┌────────────────┐  │  │         │
│  │  │  │ AssumeRole     │  │  │ Role │  │  │ Trust Policy   │  │  │         │
│  │  │  │ Permission     │  │  │      │  │  │                │  │  │         │
│  │  │  └────────────────┘  │  │      │  │  │ Principal:     │  │  │         │
│  │  └──────────────────────┘  │      │  │  │ 111111111111   │  │  │         │
│  │                            │      │  │  │                │  │  │         │
│  │                            │      │  │  │ Condition:     │  │  │         │
│  │                            │      │  │  │ ExternalId     │  │  │         │
│  │                            │      │  │  │ MFA Required   │  │  │         │
│  │                            │      │  │  └────────────────┘  │  │         │
│  │                            │      │  └──────────────────────┘  │         │
│  └────────────────────────────┘      └────────────────────────────┘         │
│                                                                              │
│  ┌────────────────────────────┐      ┌────────────────────────────┐         │
│  │     LOGGING ACCOUNT        │      │    DEV/TEST ACCOUNT        │         │
│  │   (Account: 333333333333)  │      │   (Account: 444444444444)  │         │
│  │                            │      │                            │         │
│  │  ┌──────────────────────┐  │      │  ┌──────────────────────┐  │         │
│  │  │  Cross-Account Role  │  │      │  │  Cross-Account Role  │  │         │
│  │  │  "LogArchiveRole"    │  │      │  │  "DevAccessRole"     │  │         │
│  │  └──────────────────────┘  │      │  └──────────────────────┘  │         │
│  └────────────────────────────┘      └────────────────────────────┘         │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Why This Design Was Chosen

A centralised Security Account acts as the single point of origin for all privileged access. Rather than managing IAM users in each workload account individually, operators assume roles into target accounts from one place. This keeps the blast radius of a compromised credential contained to the Security Account and makes access patterns auditable in a single CloudTrail stream.

The alternative — federated users or IAM users per account — was rejected because it creates credential sprawl, makes rotation difficult at scale, and produces fragmented audit logs across accounts.

At scale, this pattern extends to AWS Organizations with SCPs applied at the OU level and StackSets used to deploy consistent role configurations across all member accounts.

```
                        ┌─────────────────┐
                        │  SECURITY HUB   │
                        │    ACCOUNT      │
                        └────────┬────────┘
                                 │
           ┌─────────────────────┼─────────────────────┐
           │                     │                     │
           ▼                     ▼                     ▼
    ┌──────────────┐     ┌──────────────┐     ┌──────────────┐
    │   Prod OU    │     │   Dev OU     │     │  Sandbox OU  │
    ├──────────────┤     ├──────────────┤     ├──────────────┤
    │ ┌──────────┐ │     │ ┌──────────┐ │     │ ┌──────────┐ │
    │ │Account 1 │ │     │ │Account 10│ │     │ │Account 50│ │
    │ └──────────┘ │     │ └──────────┘ │     │ └──────────┘ │
    │ ┌──────────┐ │     │ ┌──────────┐ │     │ ┌──────────┐ │
    │ │Account 2 │ │     │ │Account 11│ │     │ │Account 51│ │
    │ └──────────┘ │     │ └──────────┘ │     │ └──────────┘ │
    └──────────────┘     └──────────────┘     └──────────────┘

    At scale: AWS Organizations + SCPs + StackSets
    deploy consistent roles across all accounts automatically
```

---

## Role Assumption Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      CROSS-ACCOUNT ROLE ASSUMPTION                          │
└─────────────────────────────────────────────────────────────────────────────┘

     SECURITY ACCOUNT                              WORKLOAD ACCOUNT
     ═══════════════                               ════════════════

  ┌──────────────────┐                          ┌──────────────────┐
  │  1. User/Role    │                          │                  │
  │  authenticates   │                          │                  │
  │  with MFA        │                          │                  │
  └────────┬─────────┘                          │                  │
           │                                    │                  │
           ▼                                    │                  │
  ┌──────────────────┐                          │                  │
  │  2. Calls STS    │                          │                  │
  │  AssumeRole      │─────────────────────────▶│  3. Trust Policy │
  │  with:           │                          │     Evaluated    │
  │  - Role ARN      │                          │                  │
  │  - ExternalId    │                          │  ┌────────────┐  │
  │  - Session name  │                          │  │ ✓ Account  │  │
  └────────┬─────────┘                          │  │ ✓ ExtId    │  │
           │                                    │  │ ✓ MFA      │  │
           │                                    │  └────────────┘  │
           │                                    │                  │
           │◀───────────────────────────────────│  4. Temporary    │
           │                                    │     Credentials  │
           ▼                                    │     Returned     │
  ┌──────────────────┐                          └──────────────────┘
  │  5. Use temp     │
  │  credentials     │
  │  (1 hour max)    │
  └──────────────────┘
```

---

## Implementation

### Roles Implemented

| Role | Purpose | Permissions | Trust Conditions |
|------|---------|-------------|-----------------|
| SecurityAuditRole | Read-only security review | SecurityAudit, ViewOnly managed policies | Security Account root + ExternalId + MFA |
| IncidentResponseRole | Active incident handling | EC2, VPC, IAM read + limited write (scoped actions) | Security Account root + ExternalId + MFA + IP restriction |
| DeploymentRole | CI/CD deployments | ECS, ECR, S3 (deployment bucket only) | Specific CI/CD role ARN + ExternalId (no MFA — automated pipeline) |

### Trust Policy

The trust policy defines who is allowed to assume a role. It lives in the target (workload) account and restricts assumption to a specific principal in the Security Account, with two additional conditions: an ExternalId to prevent confused deputy attacks, and an MFA requirement to ensure the assuming identity has completed a second factor.

**Annotated breakdown:**

```
┌─────────────────────────────────────────────────────────────────┐
│                     TRUST POLICY ANATOMY                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  {                                                              │
│    "Version": "2012-10-17",                                     │
│    "Statement": [                                               │
│      {                                                          │
│        "Effect": "Allow",          ◄── Explicit allow           │
│        "Principal": {                                           │
│          "AWS": "arn:aws:iam::111111111111:root"               │
│        },                          ◄── WHO can assume           │
│        "Action": "sts:AssumeRole", ◄── The action               │
│        "Condition": {                                           │
│          "StringEquals": {                                      │
│            "sts:ExternalId": "UniqueSecretValue"               │
│          },                        ◄── Confused deputy fix      │
│          "Bool": {                                              │
│            "aws:MultiFactorAuthPresent": "true"                │
│          }                         ◄── MFA required             │
│        }                                                        │
│      }                                                          │
│    ]                                                            │
│  }                                                              │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**Deployable JSON:**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::111111111111:root"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "sts:ExternalId": "UniqueSecretValue"
        },
        "Bool": {
          "aws:MultiFactorAuthPresent": "true"
        }
      }
    }
  ]
}
```

### Permission Policy (Least Privilege)

The permission policy attached to the role defines what the assuming identity can do once inside the target account. Wildcard actions were explicitly avoided. Each permission maps to a specific operational need.

```
┌─────────────────────────────────────────────────────────────────┐
│                    LEAST PRIVILEGE APPROACH                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  BAD (Overprivileged):              GOOD (Least Privilege):     │
│  ─────────────────────              ────────────────────────    │
│                                                                 │
│  {                                  {                           │
│    "Effect": "Allow",                 "Effect": "Allow",        │
│    "Action": "ec2:*",     ✗           "Action": [               │
│    "Resource": "*"                      "ec2:DescribeInstances",│
│  }                                      "ec2:DescribeVpcs",     │
│                                         "ec2:DescribeSubnets"   │
│                                       ],                   ✓    │
│                                       "Resource": "*"           │
│                                     }                           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### AssumeRole Permission (Security Account Side)

The identity in the Security Account also needs an explicit permission to call `sts:AssumeRole`. Roles are listed individually — wildcards in the resource field here would allow assumption of any role in any account, which defeats the purpose entirely.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Resource": [
        "arn:aws:iam::222222222222:role/SecurityAuditRole",
        "arn:aws:iam::333333333333:role/LogArchiveRole"
      ]
    }
  ]
}
```

### Terraform Structure

```
01-iam-cross-account-access/
├── terraform/
│   ├── main.tf                    # Root module, provider config
│   ├── variables.tf               # Account IDs, role names, external ID
│   ├── outputs.tf                 # Role ARNs + ready-to-use CLI assume-role commands
│   ├── cross-account-roles.tf     # Role resources and trust policies
│   ├── monitoring.tf              # CloudWatch metric filters and alarms
│   └── terraform.tfvars.example   # Example variable values — copy to terraform.tfvars before deploying
├── docs/
│   ├── architecture.md            # Deep-dive: design decisions, compliance mapping, cost estimate, incident response
│   └── deployment-guide.md        # Step-by-step deployment, testing, and maintenance guide
└── README.md
```

> After deploying, run `terraform output` to get pre-formatted AWS CLI commands for assuming each role. These are generated from the actual role ARNs and are ready to use.

---

## Security Controls

### Why Role Assumption Over Long-Lived Credentials

```
┌─────────────────────────────────────────────────────────────────┐
│           CREDENTIALS COMPARISON                                │
├─────────────────────┬───────────────────────────────────────────┤
│  Long-Lived Keys    │  Role Assumption                          │
├─────────────────────┼───────────────────────────────────────────┤
│  ✗ Never expire     │  ✓ Temp credentials (1-12 hours)          │
│  ✗ Can be leaked    │  ✓ Auto-rotate                            │
│  ✗ Hard to audit    │  ✓ CloudTrail logs all assumptions        │
│  ✗ No MFA support   │  ✓ Can require MFA                        │
│  ✗ Shared secrets   │  ✓ No secrets to manage                   │
└─────────────────────┴───────────────────────────────────────────┘
```

### ExternalId and the Confused Deputy Problem

Without an ExternalId condition, a third-party service that has been granted assume-role access could be tricked into assuming a role on behalf of a different customer — a confused deputy attack. The ExternalId acts as a shared secret between the two parties that only the legitimate caller knows. It does not replace MFA but defends a different threat vector.

### IP Restriction on IncidentResponseRole

The `IncidentResponseRole` includes an `aws:SourceIp` condition in its trust policy, restricting assumption to a defined list of CIDR ranges configured via `allowed_source_ips` in `variables.tf`. This role has limited write access — it can stop instances, revoke security group rules, and create snapshots — so the additional network-level control reduces the risk if credentials are stolen. The trade-off is that an incident responder working from an unexpected location (travel, home network) would be blocked. A documented break-glass procedure should cover this scenario.

### DeploymentRole Trust Design

The `DeploymentRole` intentionally omits MFA and IP conditions because it is assumed by an automated CI/CD pipeline, not a human. Instead, the trust policy restricts the principal to a specific CI/CD role ARN rather than the account root, which is a tighter trust boundary. Permissions are also scoped to only the named S3 deployment bucket by ARN rather than all S3 resources. These are deliberate compensating controls in place of MFA.

### Blast Radius of a Compromised Role

```
┌─────────────────────────────────────────────────────────────────┐
│                    BLAST RADIUS COMPARISON                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Over-Privileged Role              Properly Scoped Role         │
│  ════════════════════              ════════════════════         │
│                                                                 │
│  Compromised? Attacker can:        Compromised? Attacker can:   │
│  • Delete all resources            • Read EC2 metadata          │
│  • Exfiltrate all data             • View security groups       │
│  • Create backdoor users           • That's it.                 │
│  • Pivot to other accounts                                      │
│  • Disable logging                 Impact: LOW                  │
│  • Mine crypto                     Recovery: EASY               │
│                                                                 │
│  Impact: CATASTROPHIC                                           │
│  Recovery: DIFFICULT                                            │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Detection: CloudTrail Events to Monitor

| Event | What It Signals |
|-------|----------------|
| `AssumeRole` from unexpected IP | Credential theft or misuse |
| `AssumeRole` failures | Brute force or misconfiguration |
| Role assumption outside business hours | Anomalous access pattern |
| Cross-account access from unapproved accounts | Trust policy misconfiguration or compromise |
| Changes to trust policies (`UpdateAssumeRolePolicy`) | Privilege escalation attempt |

---

## Trade-offs

**Operational overhead:** Every new workload account requires a new role to be deployed and trust policies to be updated. Without automation via StackSets, this becomes a manual bottleneck at scale. The Terraform structure here assumes a small number of accounts — it would need to be refactored into a module called per-account for larger environments.

**Session duration:** Temporary credentials are configured for a maximum of one hour. This is the most secure default but creates friction for long-running operational tasks. Extending session duration reduces security; the right balance depends on the operational context.

**MFA dependency:** Requiring MFA on role assumption is the right call for human operators but breaks automation. CI/CD pipelines cannot interactively present an MFA token, so the `DeploymentRole` omits the MFA condition and relies on a specific trusted role ARN, tightly scoped permissions, and a named S3 bucket restriction instead. This is a deliberate trade-off, not an oversight.

**ExternalId management:** The ExternalId must be stored and referenced securely. If it leaks, it loses its protective value. In this implementation it is passed via a Terraform variable — in production it should be pulled from a secrets manager at deploy time.

---

## Gaps and Improvements

These are known limitations of this implementation relative to what a production environment would require:

- **No SCP guardrails.** AWS Organizations SCPs should be applied at the OU level to enforce a ceiling on what any role in a member account can do, regardless of what its permission policy allows. This implementation does not include SCP definitions.
- **No permission boundaries.** For environments where developers can create IAM roles themselves, permission boundaries prevent privilege escalation by capping the maximum permissions any role they create can have. Not implemented here.
- **No automated role review.** IAM Access Analyzer should be configured to flag roles with unused permissions or overly permissive trust policies. This is not wired up in the Terraform.
- **Static ExternalId.** The ExternalId is a static string. Rotating it requires coordinated updates on both sides of the trust. A more robust approach would use a time-based or per-session token.
- **Alarms defined but not connected to notifications.** `monitoring.tf` implements CloudWatch metric filters and alarms for three scenarios — SecurityAuditRole assumption, IncidentResponseRole assumption (1-minute evaluation window, flagged URGENT), and failed role assumptions exceeding 3 in 5 minutes. However, no SNS action is attached to any alarm, meaning they trigger in CloudWatch but do not notify anyone. Wiring in an SNS topic ARN is the next step to make monitoring operational.
- **Hardcoded CloudTrail log group.** ~~`monitoring.tf` assumes the log group name is `/aws/cloudtrail/organization`. If this differs in your environment, the metric filters will silently fail to match any events. This should be a variable with the hardcoded value as a default.~~ **Fixed:** Now configurable via `cloudtrail_log_group` variable with `/aws/cloudtrail/organization` as the default.
- **Single Security Account.** This design has no redundancy at the Security Account level. If the Security Account is compromised, all cross-account access flows through it. In practice, break-glass access (Project 6) should exist outside of this model.

---

## Further Reading

- [AWS Cross-Account Access](https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_cross-account-with-roles.html)
- [The Confused Deputy Problem](https://docs.aws.amazon.com/IAM/latest/UserGuide/confused-deputy.html)
- [AWS Organizations Best Practices](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_best-practices.html)
- [IAM Access Analyzer](https://docs.aws.amazon.com/IAM/latest/UserGuide/what-is-access-analyzer.html)
- [Permission Boundaries](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_boundaries.html)