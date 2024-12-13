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

# Reference the VPC called dbs
data "aws_vpc" "dbs" {
  filter {
    name   = "epa-SG"
    values = ["dbs"]
  }
}

# Reference a subnet within the dbs VPC
data "aws_subnet_ids" "dbs_subnets" {
  vpc_id = data.aws_vpc.dbs.id
}

# Create the EC2 instance in the dbs VPC
resource "aws_instance" "example" {
  ami           = "ami-0e8d228ad90af673b" # Replace with the appropriate AMI ID
  instance_type = "t2.large"
  key_name      = var.key_name

  subnet_id     = data.aws_subnet_ids.dbs_subnets.ids[0]  # Use the first subnet in the VPC
  security_groups = ["default"] # You can replace with custom security group if necessary

  tags = {
    Name = "AWS-EPA-instance"
  }
}
