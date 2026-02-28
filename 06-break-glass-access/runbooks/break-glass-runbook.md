# Break-Glass Runbook

This runbook describes the approval, activation, and recovery steps for the
break-glass emergency access process.

1) Authorization
 - Contact two authorized approvers (listed in the runbook) and obtain explicit
   approval (e.g., via ticketing system with audit trail).
 - Approval must include justification and time window.

2) Activation
 - Approver triggers the Break-Glass Controller to issue a short-lived credential
   (e.g., STS assume-role for 1 hour).
 - Use the credentials only for the stated remediation actions.

3) Monitoring & Alerts
 - All assume-role events must generate immediate alerts to the on-call security
   Slack channel and create an incident ticket.

4) Post-Incident Cleanup
 - Rotate any credentials created or exposed during the incident.
 - Revoke temporary permissions and record actions in the incident ticket.
 - Run a forensic checklist using centralized logs.

5) After-action
 - Conduct a post-mortem, identify root cause, and convert fixes into automation
   to prevent future break-glass usage where possible.
