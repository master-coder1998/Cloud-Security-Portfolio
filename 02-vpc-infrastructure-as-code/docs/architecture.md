# VPC Architecture Decisions

## Network Design

### Three-Tier Architecture

**Public Tier** (10.0.0.0/24, 10.0.1.0/24)
- Internet-facing resources only
- ALB, NAT Gateway, Bastion (optional)
- Direct internet access via Internet Gateway

**Private Tier** (10.0.10.0/24, 10.0.11.0/24)
- Application servers
- Outbound internet via NAT Gateway
- No inbound from internet

**Data Tier** (10.0.100.0/24, 10.0.101.0/24)
- Databases and sensitive data
- No internet access (inbound or outbound)
- VPC endpoints for AWS services

### Why This Design?

**Attack Surface Reduction**: Only ALB is internet-facing. Applications and databases are not directly reachable.

**Defense in Depth**: Multiple layers (NACLs + Security Groups + Network Segmentation).

**Blast Radius Containment**: Compromised app server cannot directly access internet or other tiers without going through controlled paths.

## Security Groups vs NACLs

### Security Groups (Stateful)
- Instance-level firewall
- Allow rules only
- Automatic return traffic
- Reference other security groups

### NACLs (Stateless)
- Subnet-level firewall
- Allow and deny rules
- Explicit return traffic rules
- CIDR-based only

**Strategy**: Security groups for application logic, NACLs for subnet-wide blocks and compliance.

## High Availability

- 2 Availability Zones minimum
- NAT Gateway per AZ (no single point of failure)
- Subnets spread across AZs

## Cost Optimization

**NAT Gateway**: ~$32/month per AZ + data transfer. Consider:
- Single NAT for dev/test
- VPC endpoints to avoid NAT data charges
- S3/DynamoDB gateway endpoints (free)

**VPC Endpoints**: Interface endpoints ~$7/month each. Only enable if:
- High data transfer to AWS services
- Security requirement (no internet path)
- Private subnet needs AWS API access

## Scaling Considerations

**Current**: 2 AZs, /24 subnets (251 usable IPs each)

**Growth Path**:
- Add 3rd AZ: Extend subnet pattern
- More IPs: Use /23 or /22 subnets
- Multiple environments: Separate VPCs with Transit Gateway

## VPC Flow Logs

**What's Logged**: All network traffic (accepted and rejected)

**Retention**: 30 days in CloudWatch (configurable)

**Use Cases**:
- Troubleshooting connectivity
- Security analysis
- Compliance auditing

**Cost**: ~$0.50/GB ingested + storage

## Monitoring Strategy

**Metrics to Watch**:
- NAT Gateway bandwidth
- VPC Flow Logs rejected connections
- Security group rule hits
- Unusual traffic patterns

**Alerts**:
- High rejected connection rate
- Traffic to unexpected ports
- Large data transfers

## Known Limitations

- No AWS Network Firewall (adds ~$400/month)
- No traffic inspection/IDS
- NACLs are basic (no advanced rules)
- No VPC peering configured
- No Transit Gateway for multi-VPC

## Production Hardening

1. Enable GuardDuty for threat detection
2. Add AWS Network Firewall for deep packet inspection
3. Implement VPC Traffic Mirroring for IDS
4. Add WAF in front of ALB
5. Enable AWS Shield Advanced for DDoS protection
