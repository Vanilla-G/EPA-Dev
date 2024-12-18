provider "aws" {
  region = "eu-west-2" # Specify the AWS region
}

# EC2 instance definition
resource "aws_instance" "my_ec2_instance" {
  ami           = "ami-05c172c7f0d3aed00"
  instance_type = "t2.micro"
  key_name      = "githubactions"
  subnet_id     = "subnet-01bb4c11f1b39318e"  # Directly using your specific Subnet ID

  vpc_security_group_ids = [
    "sg-0e78abc49a200c373"
  ]

  tags = {
    Name = "EPA-AWS"
  }
}

# Elastic IP Association (if required)
resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.my_ec2_instance.id
  allocation_id = data.aws_eip.existing.id  # Referencing the existing Elastic IP
}

# Referencing an existing Elastic IP
data "aws_eip" "existing" {
  id = "eipalloc-0ccc13405e62ed638"  # The Elastic IP you want to use
}

# Output the instance ID after creation
output "instance_id" {
  description = "ID of the created EC2 instance"
  value       = aws_instance.my_ec2_instance.id
}
