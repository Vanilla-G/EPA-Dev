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

resource "aws_subnet" "exampleb" {
  vpc_id                  = aws_vpc.example.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-west-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "example-subnet"
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

# Subnet Setup (Secondary subnet in eu-west-2b)
resource "aws_subnet" "example_b" {
  vpc_id                  = aws_vpc.example.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-west-2b"  # Second availability zone
  map_public_ip_on_launch = true

  tags = {
    Name = "example-subnet-b"
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
resource "aws_route_table_association" "examplex" {
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

# EBS Volume
resource "aws_ebs_volume" "example" {
  availability_zone = "eu-west-2a"
  size              = 8
  type              = "gp2"

  tags = {
    Name = "example-ebs-volume"
  }
}

# EC2 Launch Template
resource "aws_launch_template" "example" {
  name_prefix   = "example-launch-template"
  image_id      = "ami-0e8d228ad90af673b"  # Replace with the correct AMI ID
  instance_type = "t2.large"
  key_name      = var.key_name
  security_group_names = [aws_security_group.example.name]
  
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "example-instance"
    }
  }
}

# Create an SSL Certificate using AWS ACM (You can use an existing one if you already have it)
#resource "aws_acm_certificate" "example" {
#  domain_name       = "example.com"  # Replace with your domain name
#  validation_method = "DNS"

#  tags = {
#    Name = "example-cert"
#  }
#}

# Create an Elastic Load Balancer (ALB)
resource "aws_lb" "example" {
  name               = "example-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.example.id]
  subnets            = [aws_subnet.example.id, aws_subnet.example_b.id]
  
  enable_deletion_protection = false

  tags = {
    Name = "example-lb"
  }
}

# Create a target group for the Load Balancer
resource "aws_lb_target_group" "example" {
  name     = "example-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.example.id

  health_check {
    protocol = "HTTP"
    port     = "80"
    path     = "/health"
    interval = 30
    timeout  = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# Create an HTTPS listener for the Load Balancer
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.example.arn
  port              = "443"
  protocol          = "HTTPS"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.example.arn
  }

  #ssl_certificate {
  #  certificate_arn = aws_acm_certificate.example.arn
  #}
}

# Create an HTTP listener with a redirect to HTTPS
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type             = "redirect"
    redirect {
      protocol   = "HTTPS"
      port       = "443"
      status_code = "HTTP_301"
    }
  }
}

# Register Auto Scaling group with the Load Balancer
resource "aws_autoscaling_attachment" "example" {
  autoscaling_group_name = aws_autoscaling_group.example.name
  lb_target_group_arn    = aws_lb_target_group.example.arn
}

# Auto Scaling Group (ASG)
resource "aws_autoscaling_group" "example" {
  desired_capacity     = 2
  max_size             = 4
  min_size             = 1
  vpc_zone_identifier  = [aws_subnet.example.id]
  launch_template {
    id      = aws_launch_template.example.id
    version = "$Latest"
  }

  health_check_type          = "EC2"
  health_check_grace_period  = 300
  force_delete               = true
  wait_for_capacity_timeout   = "0"
  
  load_balancers = [aws_lb.example.id]  # Attach the Load Balancer
  
  tag {
    key                 = "Name"
    value               = "example-asg-instance"
    propagate_at_launch = true
  }

  lifecycle {
    ignore_changes = [desired_capacity]
  }
}

# Auto Scaling Policy for Scaling Up
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "scale_up_policy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  estimated_instance_warmup = 300
  autoscaling_group_name = aws_autoscaling_group.example.name
}

# Auto Scaling Policy for Scaling Down
resource "aws_autoscaling_policy" "scale_down" {
  name                   = "scale_down_policy"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  estimated_instance_warmup = 300
  autoscaling_group_name = aws_autoscaling_group.example.name
}

variable "key_name" {
  description = "The key pair to use for the instance"
  type        = string
}
