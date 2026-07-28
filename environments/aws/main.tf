terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "eu-central-1"
}

variable "ami_id" {
  description = "Ubuntu 24.04 AMI ID for the target region"
  type        = string
}

variable "key_name" {
  description = "EC2 key pair name for SSH access"
  type        = string
}

variable "superuser_password" {
  description = "PostgreSQL superuser password"
  type        = string
  sensitive   = true
}

variable "replication_password" {
  description = "PostgreSQL replication password"
  type        = string
  sensitive   = true
}

resource "aws_vpc" "cluster" {
  cidr_block           = "10.0.1.0/24"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = { Name = "cluster-vpc" }
}

resource "aws_subnet" "cluster" {
  vpc_id            = aws_vpc.cluster.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"

  tags = { Name = "cluster-subnet" }
}

resource "aws_internet_gateway" "cluster" {
  vpc_id = aws_vpc.cluster.id

  tags = { Name = "cluster-igw" }
}

resource "aws_route_table" "cluster" {
  vpc_id = aws_vpc.cluster.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cluster.id
  }

  tags = { Name = "cluster-rt" }
}

resource "aws_route_table_association" "cluster" {
  subnet_id      = aws_subnet.cluster.id
  route_table_id = aws_route_table.cluster.id
}

resource "aws_security_group" "cluster" {
  name   = "cluster-sg"
  vpc_id = aws_vpc.cluster.id

  ingress {
    description = "Internal cluster traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "cluster-sg" }
}

module "postgres" {
  source               = "../../modules/postgres/aws"
  subnet_id            = aws_subnet.cluster.id
  ami_id               = var.ami_id
  key_name             = var.key_name
  security_group_ids   = [aws_security_group.cluster.id]
  superuser_password   = var.superuser_password
  replication_password = var.replication_password
}

module "haproxy" {
  source             = "../../modules/haproxy/aws"
  subnet_id          = aws_subnet.cluster.id
  ami_id             = var.ami_id
  key_name           = var.key_name
  security_group_ids = [aws_security_group.cluster.id]
}
