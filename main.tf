terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-west-2"
}

# Reference the existing VPC by tag "dbs" (the same VPC where the RDS is)
data "aws_vpc" "dbs" {
  filter {
    name   = "tag:Name"
    values = ["dbs"]  # Replace with your actual VPC tag
  }
}

# Reference the existing subnet by ID (subnet-0f0df08285283bc0b)
data "aws_subnet" "existing_subnet" {
  id = "subnet-0f0df08285283bc0b"  # Use the existing subnet ID here
}

# EC2 instance setup in the same subnet as the RDS instance (existing subnet)
resource "aws_instance" "example" {
  ami           = "ami-0e8d228ad90af673b"  # Replace with the appropriate AMI ID
  instance_type = "t2.large"
  subnet_id     = data.aws_subnet.existing_subnet.id  # Reference the existing subnet ID
  key_name      = var.key_name

  # Security group for SSH (you can manage security groups manually outside of Terraform)
  vpc_security_group_ids = []  # Leave empty for manual assignment

  tags = {
    Name = "AWS-EPA-instance"
  }
}

variable "key_name" {
  description = "The key pair to use for the instance"
  type        = string
}

# Elastic IP Association (if required)
resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.example.id
  allocation_id = data.aws_eip.existing.id  # Referencing the existing Elastic IP
}

# Referencing an existing Elastic IP
data "aws_eip" "existing" {
  id = "eipalloc-0ccc13405e62ed638"  # The Elastic IP you want to use
}
