# Incident Response — Using Centralized Logs

Steps to investigate a suspected incident using the central log archive:

1. Identify the time window of interest and corresponding CloudTrail log files.
2. Validate log file digests using CloudTrail log file validation.
3. Search for privilege changes, console logins, and `AssumeRole` events.
4. Correlate with VPC Flow Logs and application logs to build a timeline.
5. Preserve evidence by marking objects and exporting any derived artifacts.

Include playbooks for escalation and communication in this document as needed.
