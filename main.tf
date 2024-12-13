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

# EC2 instance setup
resource "aws_instance" "example" {
  ami           = "ami-0e8d228ad90af673b" # Replace with the appropriate AMI ID
  instance_type = "t2.large"
  subnet_id     = aws_subnet.example.id
  key_name      = var.key_name

  vpc_security_group_ids = [aws_security_group.example.id]

  tags = {
    Name = "AWS-EPA-instance"
  }
}

variable "key_name" {
  description = "The key pair to use for the instance"
  type        = string
  
}

# Elastic IP Association
resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.example.id
  allocation_id = data.aws_eip.existing.id # Referencing the existing Elastic IP
}

# Referencing an existing Elastic IP
data "aws_eip" "existing" {
  id = "eipalloc-0ccc13405e62ed638" # The Elastic IP you want to use
}
