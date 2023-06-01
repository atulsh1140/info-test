
# Configure the AWS Provider
provider "aws" {
  region     = "us-east-1"

}

# Creating VPC, name, CIDR & tags.

resource "aws_vpc" "dev-vpc" {
    cidr_block = "10.0.0.0/16"
    instance_tenancy = "default"
    enable_dns_support = "true"
    enable_dns_hostnames = "true"
    tags = {
        Name = "dev-vpc"
    }
  
}

# Creating Public Subnets for the VPC 
resource "aws_subnet" "dev-public-1" {
    vpc_id = aws_vpc.dev-vpc.id
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = "true"
    availability_zone = "us-east-1a"
    tags = {
        Name = "dev-public-1"
    }
  
}

# Creating Private Subnets for the VPC 

resource "aws_subnet" "dev-private-1" {
    vpc_id = aws_vpc.dev-vpc.id
    cidr_block = "10.0.2.0/24"
    map_public_ip_on_launch = "false"
    availability_zone = "us-east-1d"
    tags = {
      "Name" = "dev-private-1"
    }
}

# Creating Internet Gateway for VPC

resource "aws_internet_gateway" "dev-igw" {
    vpc_id = aws_vpc.dev-vpc.id
    tags = {
      "Name" = "Dev-igw"
    }  
}

# Creating Public Route Table for VPC

resource "aws_route_table" "dev-public-rt" {
    vpc_id = aws_vpc.dev-vpc.id
    route  {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.dev-igw.id
    }
    tags = {
      "Name" = "dev-public-rt"
    }
}

# Creating Private Route Table for VPC

resource "aws_route_table" "dev-private-rt" {
    vpc_id = aws_vpc.dev-vpc.id
    route  {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.nat-gateway.id
    }
    tags = {
      "Name" = "dev-private-rt"
    }
}

# Create EIP for the IGW

resource "aws_eip" "myEIP" {
   vpc   = true 
   tags = {
     "Name" = "Nat-EIP"
   }
 }


# Create NAT Gateway resource and attach it to the VPC
resource "aws_nat_gateway" "nat-gateway" {
   allocation_id = aws_eip.myEIP.id
   subnet_id = aws_subnet.dev-public-1.id
   tags = {
     "Name" = "nat-gateway"
   }
 }

# Associating the Public RT with the public subnet

resource "aws_route_table_association" "public-rt-asso" {
subnet_id = aws_subnet.dev-public-1.id
route_table_id = aws_route_table.dev-public-rt.id 
}

# Associating the Private RT with the Private subnet

resource "aws_route_table_association" "private-rt-asso" {
subnet_id = aws_subnet.dev-private-1.id
route_table_id = aws_route_table.dev-private-rt.id
}   


# Create a security Group

resource "aws_security_group" "SecurityGroup-rule" {
  name        = "SecurityGroup-rule"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.dev-vpc.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]

  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "SecurityGroup-rule"
  }
}