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

# Reference an existing VPC by name (assuming it has the tag "Name=dbs")
data "aws_vpc" "dbs" {
  filter {
    name   = "tag:Name"
    values = ["dbs"]  # Replace VPC name if different
  }
}

# Create a subnet in Availability Zone eu-west-2a
resource "aws_subnet" "example_subnet" {
  vpc_id                  = data.aws_vpc.dbs.id
  cidr_block              = "172.30.3.0/24"  # New CIDR block in eu-west-2a (replace with unused CIDR)
  availability_zone       = "eu-west-2a"     # Same AZ as your RDS instance

  map_public_ip_on_launch = true  # Optional: assign public IPs on instance launch

  tags = {
    Name = "example-subnet"
  }
}

# EC2 instance setup with the referenced subnet in eu-west-2a
resource "aws_instance" "example" {
  ami           = "ami-0e8d228ad90af673b"  # Replace with the appropriate AMI ID
  instance_type = "t2.large"
  subnet_id     = aws_subnet.example_subnet.id  # Use the subnet created in eu-west-2a
  key_name      = var.key_name

  # No security group defined; ill assign it manually outside Terraform
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
