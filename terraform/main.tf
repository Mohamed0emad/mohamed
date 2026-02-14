terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
  access_key = var.access_key
  secret_key = var.secret_key
}

# 1. تعريف الـ VPC
resource "aws_vpc" "monitoring_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = { Name = "monitoring-vpc" }
}

# 2. الـ Subnet العام (Public)
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.monitoring_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a" # تأكد أن هذا الـ AZ يدعم c7i-flex
  tags = { Name = "monitoring-public-subnet" }
}

# 3. بوابة الإنترنت والراوتنج
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.monitoring_vpc.id
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.monitoring_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# 4. السكيورتي جروب (فتح بورت 22 للـ SSH)
resource "aws_security_group" "ec2_security_group" {
  name        = "monitoring-sg"
  vpc_id      = aws_vpc.monitoring_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 5. السيرفر Ubuntu بمواصفات c7i-flex.large
resource "aws_instance" "Monitoring_server" {
  # AMI الخاص بـ Ubuntu 22.04 LTS في منطقة us-east-1
  # ملاحظة: إذا كنت تستخدم منطقة أخرى، ستحتاج لتغيير الـ ID
  ami           = "ami-0c7217cdde317cfec" 
  instance_type = "c7i-flex.large"
  key_name      = var.key_name

  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.ec2_security_group.id]

  tags = {
    Name = "Monitoring_Ubuntu_Server"
  }
}

output "public_ip" {
  value = aws_instance.Monitoring_server.public_ip
}
