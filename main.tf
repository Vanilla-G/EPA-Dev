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
    values = ["dbs"]  # Replace with your actual VPC name if different
  }
}

# Reference a subnet within that VPC by name (assuming you know its tag or another attribute)
data "aws_subnet" "example_subnet" {
  filter {
    name   = "tag:Name"
    values = ["dbs"]  # Replace with your actual subnet name
  }
  vpc_id = data.aws_vpc.dbs.id  # Ensures it matches the dbs VPC
}

# EC2 instance setup with a referenced subnet and security group
resource "aws_instance" "example" {
  ami           = "ami-0e8d228ad90af673b"  # Replace with the appropriate AMI ID
  instance_type = "t2.large"
  subnet_id     = data.aws_subnet.example_subnet.id  # Use the referenced subnet ID
  key_name      = var.key_name

  vpc_security_group_ids = ["sg-029b358b17663657b"]  # Replace with your actual security group ID

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


