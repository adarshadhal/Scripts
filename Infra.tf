
# VPC Creation
resource "aws_vpc" "myvpc" {
  region = ""
  cidr_block = "192.168.0.0/16"
  tags = {
    Name = "myvpc"
  }
}
# Private Subnet Creation 
resource "aws_subnet" "my-private-subnet" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "192.168.32.0/19"
  availability_zone = "ap-south-2a"
  map_public_ip_on_launch = "false"
  tags = {
    Name = "My-Private-Subnet"
  }
}
# Public Subnet Creation 
resource "aws_subnet" "my-public-subnet" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "192.168.64.0/19"
  availability_zone = "ap-south-2b"
  map_public_ip_on_launch = "true"
  tags = {
    Name = "My-Public-Subnet"
  }
}

# IG Creation
resource "aws_internet_gateway" "my-igw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "My-igw"
  }
}

# Route Tabele Creation and attached with vpc
resource "aws_route_table" "My-Rt" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my-igw.id
  }

  tags = {
    Name = "My-RT"
  }
}
resource "aws_route_table_association" "subnet-association" {
  subnet_id      = aws_subnet.my-public-subnet.id
  route_table_id = aws_route_table.My-Rt.id
}

# Security Group Creation
resource "aws_security_group" "My-sg" {
  name        = "allow_tcp"
  description = "Allow tcp inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.myvpc.id

  tags = {
    Name = "My-sg"
  }
}
resource "aws_vpc_security_group_ingress_rule" "HTTPS" {
  security_group_id = aws_security_group.My-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = "443" 
  ip_protocol       = "tcp"
  to_port           = "443" 
}
resource "aws_vpc_security_group_ingress_rule" "SSH" {
  security_group_id = aws_security_group.My-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = "22" 
  ip_protocol       = "tcp"
  to_port           = "22" 
}
resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.My-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}



resource "aws_instance" "my-ec2" {
    ami = "ami-0bd4cda58efa33d23"
    key_name = "Adarsha2581"
    instance_type = "t3.micro"
    vpc_security_group_ids = [aws_security_group.My-sg.id]
    subnet_id = aws_subnet.my-public-subnet.id
    tags = {
        Name = "My-ec2-1"
        }
}
