# E-Commerce Platform Architecture

This diagram represents the target system for threat modeling analysis.

```
                                    Internet
                                       │
                                       ▼
                        ┌──────────────────────────┐
                        │   CloudFront (CDN)       │
                        │   - Static assets        │
                        │   - WAF enabled          │
                        └────────────┬─────────────┘
                                     │
                        ┌────────────┴─────────────┐
                        │                          │
                        ▼                          ▼
            ┌───────────────────┐      ┌───────────────────┐
            │  Route 53 (DNS)   │      │   S3 (Static)     │
            └─────────┬─────────┘      │   - Images        │
                      │                │   - CSS/JS        │
                      ▼                └───────────────────┘
            ┌───────────────────┐
            │  ALB (Public)     │
            │  - HTTPS only     │
            │  - Security groups│
            └─────────┬─────────┘
                      │
        ┌─────────────┼─────────────┐
        │             │             │
        ▼             ▼             ▼
   ┌────────┐   ┌────────┐   ┌────────┐
   │  ECS   │   │  ECS   │   │  ECS   │  Web Tier
   │  Task  │   │  Task  │   │  Task  │  (Private Subnet)
   └───┬────┘   └───┬────┘   └───┬────┘
       │            │            │
       └────────────┼────────────┘
                    │
                    ▼
         ┌─────────────────────┐
         │  Internal ALB       │
         │  (Private)          │
         └──────────┬──────────┘
                    │
        ┌───────────┼───────────┐
        │           │           │
        ▼           ▼           ▼
   ┌────────┐  ┌────────┐  ┌────────┐
   │  ECS   │  │  ECS   │  │  ECS   │  API Tier
   │  Task  │  │  Task  │  │  Task  │  (Private Subnet)
   └───┬────┘  └───┬────┘  └───┬────┘
       │           │           │
       └───────────┼───────────┘
                   │
       ┌───────────┼───────────┐
       │           │           │
       ▼           ▼           ▼
   ┌────────┐  ┌────────┐  ┌────────┐
   │  RDS   │  │ Redis  │  │   S3   │  Data Tier
   │Primary │  │ElastiC.│  │ Upload │  (Data Subnet)
   └───┬────┘  └────────┘  └────────┘
       │
       ▼
   ┌────────┐
   │  RDS   │
   │Replica │
   └────────┘

Supporting Services:
┌─────────────────────────────────────────────┐
│  Secrets Manager  │  KMS  │  CloudTrail     │
│  IAM Roles        │  WAF  │  CloudWatch     │
│  VPC Flow Logs    │  SNS  │  Lambda         │
└─────────────────────────────────────────────┘
```

## System Components

### External Entry Points
1. **CloudFront** - CDN for static content delivery
2. **Route 53** - DNS resolution
3. **Public ALB** - HTTPS load balancer

### Application Tiers
1. **Web Tier** - Frontend application (ECS containers)
2. **API Tier** - Backend services (ECS containers)
3. **Data Tier** - RDS PostgreSQL, Redis, S3

### Security Services
1. **WAF** - Web application firewall
2. **Secrets Manager** - Credential storage
3. **KMS** - Encryption key management
4. **CloudTrail** - Audit logging
5. **VPC Flow Logs** - Network traffic logging

## Trust Boundaries

```
┌─────────────────────────────────────────────────────┐
│ Trust Boundary 1: Internet → AWS                   │
│ - CloudFront, Route 53, Public ALB                  │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│ Trust Boundary 2: Public Subnet → Private Subnet   │
│ - Web tier → API tier                               │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│ Trust Boundary 3: Private Subnet → Data Subnet     │
│ - API tier → Database tier                          │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│ Trust Boundary 4: Application → AWS Services       │
│ - ECS tasks → Secrets Manager, KMS, S3              │
└─────────────────────────────────────────────────────┘
```

## Data Flow

### User Request Flow
1. User → CloudFront → WAF → ALB
2. ALB → Web Tier (ECS)
3. Web Tier → Internal ALB → API Tier
4. API Tier → RDS/Redis/S3

### Authentication Flow
1. User credentials → API Tier
2. API Tier → Secrets Manager (DB credentials)
3. API Tier → RDS (query)
4. Response → User

### File Upload Flow
1. User → Web Tier
2. Web Tier → API Tier
3. API Tier → S3 (presigned URL)
4. User → S3 (direct upload)

## Assets

### Critical Assets
- Customer PII (names, emails, addresses)
- Payment information (tokenized)
- User credentials (hashed passwords)
- Session tokens
- API keys
- Database credentials

### High-Value Assets
- Product catalog
- Order history
- Inventory data
- Application logs

### Supporting Assets
- Static content (images, CSS, JS)
- Configuration data
- Metrics and monitoring data
