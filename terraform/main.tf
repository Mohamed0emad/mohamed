terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region     = "us-east-1"
  access_key = var.access_key
  secret_key = var.secret_key
}

# استخدم الـ Security Group الموجود بدل ما تنشئ واحد جديد
data "aws_security_group" "ec2_security_group" {
  filter {
    name   = "group-name"
    values = ["ec2 security group"]   # الاسم الموجود اللي عامل مشاكل
  }

  filter {
    name   = "vpc-id"
    values = ["vpc-05d2466ca39ef6ff5"] # الـ VPC اللي فيه الـ SG
  }
}

resource "aws_instance" "Monitoring_server" {
  ami           = "ami-0030e4319cbf4dbf2"
  instance_type = "c7i-flex.large"
  key_name      = "starbucks1"

  # اربط الـ instance بالـ SG الموجود
  vpc_security_group_ids = [data.aws_security_group.ec2_security_group.id]

  tags = {
    Name = var.instance_name
  }
}
