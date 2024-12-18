provider "aws" {
  region = "eu-west-2" # Specify the AWS region
}

resource "aws_instance" "my_ec2_instance" {
  ami           = "ami-05c172c7f0d3aed00"
  instance_type = "t2.micro"
  key_name      = "githubactions"
  subnet_id     = aws_subnet.selected_subnet.id

  vpc_security_group_ids = [
    "sg-0e78abc49a200c373"
  ]

  tags = {
    Name = "EPA-AWS"
  }
}

# Dynamically fetch a subnet from the specified VPC
data "aws_subnet_ids" "available" {
  vpc_id = "vpc-0ef3faf243858d782"
}

data "aws_subnet" "selected_subnet" {
  id = data.aws_subnet_ids.available.ids[0] # Select the first available subnet
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

output "instance_id" {
  description = "ID of the created EC2 instance"
  value       = aws_instance.my_ec2_instance.id
}
