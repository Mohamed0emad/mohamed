terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Provider configuration
provider "aws" {
  region     = "us-east-1"
  access_key = var.access_key
  secret_key = var.secret_key
}

# Vpc ID
data "aws_vpc" "my-vpc-nti" {
  id = "vpc-085567c80ce4afc2a"
}

#  create Security Group and attach VPC
resource "aws_security_group" "ec2_security_group" {
  name        = "monitoring-server-sg"
  description = "allow access on port 22"
  vpc_id      = data.aws_vpc.selected.id # الربط الصحيح بالـ VPC بتاعتك

  ingress {
    description      = "ssh access"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Monitoring server security group"
  }
}

# crate EC2 Instance
resource "aws_instance" "Monitoring_server" {
  ami           = "ami-0938a60d87953e820"
  instance_type = "c7i-flex.large"
  
  # use vpc_security_group_ids  
  vpc_security_group_ids = [aws_security_group.ec2_security_group.id]
  
  key_name = var.key_name

  tags = {
    Name = var.instance_name
  }
}

output "instance_ip" {
  value = aws_instance.Monitoring_server.public_ip
}
