provider "aws" {
  region = "" # Your Region 
}

# Configure the S3 backend
terraform {
  backend "s3" {
    bucket         = "" # Your state bucket
    key            = "YOURFOLDER/terraform.tfstate" # Be aware of the state folder, good practice to use the same name of this terraform folder
    region         = ""  # Your Region
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}

# Create VPC
resource "aws_vpc" "eks_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "eks-vpc"
  }
}

# Create Subnets with auto-assign public IP enabled
resource "aws_subnet" "eks_subnets" {
  count             = 3  # Adjust count as per your subnet requirement
  vpc_id            = aws_vpc.eks_vpc.id
  cidr_block        = "10.0.${count.index + 1}.0/24"
  availability_zone = element(["us-east-2a", "us-east-2b", "us-east-2c"], count.index)  # Adjust AZs as needed
  map_public_ip_on_launch = true  # Enable auto-assign public IP

  tags = {
    Name = "eks-subnet-${count.index}"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.eks_vpc.id

  tags = {
    Name = "igw"
  }
}

# Create Elastic IP for NAT Gateway
resource "aws_eip" "nat_eip" {
  depends_on = [aws_internet_gateway.igw]
  vpc        = true
}

# Create NAT Gateway
resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = element(aws_subnet.eks_subnets[*].id, 0)  # Place NAT gateway in the first subnet

  tags = {
    Name = "ngw"
  }
}

# Create Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.eks_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public"
  }
}

# Create Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.eks_vpc.id

  route {
    cidr_block    = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngw.id
  }

  tags = {
    Name = "private"
  }
}

# Associate Subnets with Route Tables
resource "aws_route_table_association" "public" {
  count          = 1
  subnet_id      = element(aws_subnet.eks_subnets[*].id, 0)  # Associate the first subnet with the public route table
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = element(aws_subnet.eks_subnets[*].id, count.index + 1)  # Associate the other subnets with the private route table
  route_table_id = aws_route_table.private.id
}


# Create Security Group for EKS Cluster
resource "aws_security_group" "eks_sg" {
  name        = "eks-security-group"
  description = "EKS cluster security group"
  vpc_id      = aws_vpc.eks_vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
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
    Name = "eks-security-group"
  }
}

# Outputs
output "vpc_id" {
  value = aws_vpc.eks_vpc.id
}

output "subnet_ids" {
  value = aws_subnet.eks_subnets[*].id
}

output "security_group_id" {
  value = aws_security_group.eks_sg.id
}
