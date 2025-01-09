

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# Create a VPC

resource "aws_vpc" "amit-terraform" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = "true"


  tags = {
    Name = "amit-terraform"
  }
}

# Create IGW
resource "aws_internet_gateway" "IGW-terraform" {
  vpc_id = aws_vpc.amit-terraform.id

  tags = {
    Name = "IGW-terraform"
  }
}

# Create Subnet

resource "aws_subnet" "Public-subnet" {
  vpc_id     = aws_vpc.amit-terraform.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "Public-Subnet"
  }
}

# Creating a route table

resource "aws_route_table" "Public-RouteTable" {
  vpc_id = aws_vpc.amit-terraform.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.IGW-terraform.id
  }

  tags = {
    Name    = "Public-RouteTable"
    Service = "Terraform"
  }
}

## Creating aws_route_table_association

resource "aws_route_table_association" "public-routetable-association" {
  subnet_id      = aws_subnet.Public-subnet.id
  route_table_id = aws_route_table.Public-RouteTable.id
}

# Security Groups

resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.amit-terraform.id


  ingress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}


