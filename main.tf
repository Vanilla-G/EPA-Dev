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

# VPC Setup
resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "example-vpc"
  }
}

# Subnet Setup
resource "aws_subnet" "example" {
  vpc_id                  = aws_vpc.example.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "example-subnet"
  }
}

# Internet Gateway Setup
resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id

  tags = {
    Name = "example-igw"
  }
}

# Route Table Setup
resource "aws_route_table" "example" {
  vpc_id = aws_vpc.example.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.example.id
  }

  tags = {
    Name = "example-route-table"
  }
}

# Route Table Association
resource "aws_route_table_association" "example" {
  subnet_id      = aws_subnet.example.id
  route_table_id = aws_route_table.example.id
}

# Security Group Setup
resource "aws_security_group" "example" {
  vpc_id = aws_vpc.example.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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

  tags = {
    Name = "example-security-group"
  }
}

# Create an EBS Volume (no snapshot)
resource "aws_ebs_volume" "example" {
  availability_zone = "eu-west-2a"  # Ensure this matches your EC2 instance's AZ
  size              = 8  # Size in GiB
  type              = "gp2"  # General Purpose SSD (gp2)
  tags = {
    Name = "example-ebs-volume"
  }

  lifecycle {
    #prevent_destroy = true  # Prevent deletion of this volume if Terraform destroy is run
  }
}

# Attach the EBS Volume to the EC2 instance
resource "aws_volume_attachment" "example" {
  device_name = "/dev/sdf" # Device name inside the EC2 instance (or /dev/nvme1n1 for NVMe instances)
  volume_id   = aws_ebs_volume.example.id
  instance_id = aws_instance.example.id

  lifecycle {
    #prevent_destroy = true  # Prevent destruction of the attachment if the volume is destroyed
  }

  depends_on = [
    aws_instance.example
  ]
}

# EC2 instance setup
resource "aws_instance" "example" {
  ami           = "ami-0e8d228ad90af673b" # Replace with the appropriate AMI ID
  instance_type = "t2.large"
  subnet_id     = aws_subnet.example.id

  vpc_security_group_ids = [aws_security_group.example.id]

  user_data = <<-EOF
             #!/bin/bash
              
              # Log file path
              LOG_FILE="/var/log/script-execution.log"
              # Function to check the exit status of the last executed command
              check_exit_status() {
                  if [ $? -ne 0 ]; then
                      echo -e "\e[31mError: $1 failed.\e[0m" | tee -a $LOG_FILE
                      exit 1
                  else
                      echo -e "\e[32m$1 succeeded.\e[0m" | tee -a $LOG_FILE
                  fi
              }
              # create log file and u+g=ubuntu
              sudo touch $LOG_FILE
              sudo chown $(whoami):$(whoami) /var/log/script-execution.log
              # Boot time into logs
              sudo uptime > $LOG_FILE
              # Update package lists
              sudo echo "Running apt update..." | tee -a $LOG_FILE
              sudo apt -y update
              check_exit_status "apt update"
              # Upgrade installed packages
              sudo echo "Running apt upgrade..." | tee -a $LOG_FILE
              sudo apt -y upgrade
              check_exit_status "apt upgrade"
              # Clone the GitHub repository
              sudo echo "Cloning GitHub repository..." | tee -a $LOG_FILE
              sudo git clone https://github.com/Vanilla-G/EPA-Dev.git /root/EPA
              check_exit_status "clone repo"
              # Change permissions of the cloned repository
              sudo echo "Changing permissions of the cloned repository..." | tee -a $LOG_FILE
              sudo chmod -R 755 /root/EPA
              check_exit_status "chmod"
              # We Need to run lemp-setup.sh script
              sudo bash /root/EPA/lemp-setup.sh
              EOF
  tags = {
    Name = "AWS-EPA-instance"
  }
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