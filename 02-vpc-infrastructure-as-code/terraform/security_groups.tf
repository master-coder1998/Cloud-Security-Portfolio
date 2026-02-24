# ALB Security Group
resource "aws_security_group" "alb" {
  name_description = "${var.environment}-alb-sg"
  description      = "Security group for Application Load Balancer"
  vpc_id           = aws_vpc.main.id

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP from internet (redirect to HTTPS)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description     = "To application servers"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  tags = {
    Name = "${var.environment}-alb-sg"
  }
}

# Application Security Group
resource "aws_security_group" "app" {
  name_description = "${var.environment}-app-sg"
  description      = "Security group for application servers"
  vpc_id           = aws_vpc.main.id

  ingress {
    description     = "From ALB only"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description     = "To database"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.database.id]
  }

  egress {
    description = "HTTPS for package updates"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-app-sg"
  }
}

# Database Security Group
resource "aws_security_group" "database" {
  name_description = "${var.environment}-db-sg"
  description      = "Security group for database servers"
  vpc_id           = aws_vpc.main.id

  ingress {
    description     = "PostgreSQL from app servers only"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  # No egress rules - database should not initiate outbound connections

  tags = {
    Name = "${var.environment}-db-sg"
  }
}

# Bastion Security Group (optional - for SSH access)
resource "aws_security_group" "bastion" {
  count            = var.enable_bastion ? 1 : 0
  name_description = "${var.environment}-bastion-sg"
  description      = "Security group for bastion host"
  vpc_id           = aws_vpc.main.id

  ingress {
    description = "SSH from allowed IPs"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.bastion_allowed_cidrs
  }

  egress {
    description = "SSH to private instances"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = {
    Name = "${var.environment}-bastion-sg"
  }
}
