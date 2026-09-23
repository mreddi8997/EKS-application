terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.vpc_name}-rds-subnet-group"
  subnet_ids = var.rds_db_subnet_ids

  tags = {
    Name = "${var.vpc_name}-rds-subnet-group"
  }
}

resource "aws_db_instance" "main" {
  allocated_storage               = var.rds_allocated_storage
  storage_type                    = var.rds_storage_type
  engine                          = var.rds_engine
  engine_version                  = var.rds_engine_version
  instance_class                  = var.rds_instance_class
  db_name                         = var.rds_db_name
  username                        = var.rds_username
  manage_master_user_password     = true
  parameter_group_name            = var.rds_parameter_group_name
  skip_final_snapshot             = var.rds_skip_final_snapshot
  publicly_accessible             = false
  vpc_security_group_ids          = [aws_security_group.rds.id]
  db_subnet_group_name            = aws_db_subnet_group.main.name
  kms_key_id                      = aws_kms_key.rds_key.arn
  storage_encrypted               = true
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]


  tags = {
    Name = "${var.vpc_name}-rds-instance"
  }
}

resource "aws_security_group" "rds" {
  name        = "${var.vpc_name}-rds-sg"
  description = "Security group for RDS instance"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = var.rds_allowed_security_groups
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = var.rds_allowed_security_groups 
  }
}

resource "aws_kms_key" "rds_key" {
  description = "KMS Key for rds"
}
