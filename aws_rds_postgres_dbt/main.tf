terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }

    kestra = {
      source = "kestra-io/kestra" # namespace of Kestra provider
      version = "~> 0.7.0" # don't worry about 0.7.0 being displayed here - the provider works across the latest version as well
    }
  }
}


provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "4.0.2"
  name                 = "kestra"
  cidr                 = "10.0.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  public_subnets       = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  enable_dns_hostnames = true
  enable_dns_support   = true
}


resource "aws_db_subnet_group" "kestra" {
  name       = "kestra"
  subnet_ids = module.vpc.public_subnets

  tags = {
    Name = "kestra"
  }
}

resource "aws_security_group" "rds" {
  name   = "kestra_rds"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "kestra_rds"
  }
}

resource "aws_db_parameter_group" "kestra" {
  name   = "kestra"
  family = "postgres14"

  parameter {
    name  = "log_connections"
    value = "1"
  }
}

resource "aws_db_instance" "kestra" {
  identifier             = "kestra"
  instance_class         = var.db_instance
  allocated_storage      = 5
  engine                 = "postgres"
  engine_version         = "14.6"
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.kestra.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  parameter_group_name   = aws_db_parameter_group.kestra.name
  publicly_accessible    = true
  skip_final_snapshot    = true
}
