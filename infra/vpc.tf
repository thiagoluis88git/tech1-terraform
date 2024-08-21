/* VPC */
resource "aws_vpc" "fiap-vpc" {
  cidr_block = "10.123.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "fiap-vpc"
  }
}

# Create Elastic IP
resource "aws_eip" "vpc-elastic-ip" {
  vpc = true
}

/* Internet gateway for the public subnet */
resource "aws_internet_gateway" "fiap-vpc-igw" {
  vpc_id = "${aws_vpc.fiap-vpc.id}"
  tags = {
    Name        = "fiap-vpc-igw"
  }
}

/* NAT Gateway */
resource "aws_nat_gateway" "fastfood-nat-gateway" {
  allocation_id = aws_eip.vpc-elastic-ip.id
  subnet_id     = aws_subnet.public-subnet-a.id

  tags = {
    Name = "NAT Gateway for Custom Kubernetes Cluster"
  }
}

/* Private Subnet A */
resource "aws_subnet" "private-subnet-a" {
  vpc_id            = aws_vpc.fiap-vpc.id
  cidr_block        = "10.123.1.0/24"
  availability_zone = "us-east-1a"

  map_public_ip_on_launch = false

  tags = {
    Name = "private-subnet-a"
    "kubernetes.io/role/internal-elb" = 1
  }
}

/* Private Subnet B */
resource "aws_subnet" "private-subnet-b" {
  vpc_id            = aws_vpc.fiap-vpc.id
  cidr_block        = "10.123.2.0/24"
  availability_zone = "us-east-1b" 

  map_public_ip_on_launch = false

  tags = {
    Name = "private-subnet-b"
    "kubernetes.io/role/internal-elb" = 1
  }
}

/* Public Subnet A */
resource "aws_subnet" "public-subnet-a" {
  vpc_id            = aws_vpc.fiap-vpc.id
  cidr_block        = "10.123.3.0/24"
  availability_zone = "us-east-1a"

  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-a"
    "kubernetes.io/role/elb" = 1
  }
}

/* Public Subnet B */
resource "aws_subnet" "public-subnet-b" {
  vpc_id            = aws_vpc.fiap-vpc.id
  cidr_block        = "10.123.4.0/24"
  availability_zone = "us-east-1b" 

  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-b"
    "kubernetes.io/role/elb" = 1
  }
}

/* Routing table for private subnet */
resource "aws_route_table" "private-rt" {
  vpc_id = "${aws_vpc.fiap-vpc.id}"
  tags = {
    Name        = "vpc-private-route-table"
  }
}

/* Routing table for public subnet */
resource "aws_route_table" "public-rt" {
  vpc_id = "${aws_vpc.fiap-vpc.id}"
  tags = {
    Name        = "vpc-public-route-table"
  }
}

resource "aws_route" "public_internet_gateway" {
  route_table_id         = "${aws_route_table.public-rt.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.fiap-vpc-igw.id}"
}

/* Route table associations */
resource "aws_route_table_association" "public-1a" {
  # count          = "${length(var.public_subnets_cidr)}"
  subnet_id      = "${aws_subnet.public-subnet-a.id}"
  route_table_id = "${aws_route_table.public-rt.id}"
}

resource "aws_route_table_association" "public-1b" {
  # count          = "${length(var.public_subnets_cidr)}"
  subnet_id      = "${aws_subnet.public-subnet-b.id}"
  route_table_id = "${aws_route_table.public-rt.id}"
}

resource "aws_route_table_association" "private-1a" {
  # count          = "${length(var.private_subnets_cidr)}"
  subnet_id      = "${aws_subnet.private-subnet-a.id}"
  route_table_id = "${aws_route_table.private-rt.id}"
}

resource "aws_route_table_association" "private-1b" {
  # count          = "${length(var.private_subnets_cidr)}"
  subnet_id      = "${aws_subnet.private-subnet-b.id}"
  route_table_id = "${aws_route_table.private-rt.id}"
}

/*==== VPC's Default Security Group ======*/
resource "aws_security_group" "default" {
  name        = "vpc-default-sg"
  description = "Default security group to allow inbound/outbound from the VPC"
  vpc_id      = "${aws_vpc.fiap-vpc.id}"
  depends_on  = [aws_vpc.fiap-vpc]
  ingress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    self      = true
  }
  
  egress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    self      = "true"
  }
  tags = {
    Environment = "Default security group"
  }
}