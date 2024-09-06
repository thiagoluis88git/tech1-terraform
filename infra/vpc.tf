
provider "aws" {
  # profile = var.networking.profile
  region = var.networking.region
}

/* VPC */
resource "aws_vpc" "fiap-vpc" {
  cidr_block = var.networking.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = var.networking.vpc_name
  }
}

# EIPs
resource "aws_eip" "elastic-ip" {
  count      = var.networking.private_subnets == null || var.networking.nat_gateways == false ? 0 : length(var.networking.private_subnets)
  vpc        = true
  depends_on = [aws_internet_gateway.fiap-vpc-igw]

  tags = {
    Name = "eip-${count.index}"
  }
}

/* Internet gateway for the public subnet */
resource "aws_internet_gateway" "fiap-vpc-igw" {
  vpc_id = "${aws_vpc.fiap-vpc.id}"
  tags = {
    Name        = "fiap-vpc-igw"
  }
}

# NAT GATEWAYS
resource "aws_nat_gateway" "nats" {
  count             = var.networking.private_subnets == null || var.networking.nat_gateways == false ? 0 : length(var.networking.private_subnets)
  subnet_id         = aws_subnet.public-subnet[count.index].id
  connectivity_type = "public"
  allocation_id     = aws_eip.elastic-ip[count.index].id
  depends_on        = [aws_internet_gateway.fiap-vpc-igw]
}

/* Private Subnets */
resource "aws_subnet" "private-subnet" {
  count             = var.networking.private_subnets == null || var.networking.private_subnets == "" ? 0 : length(var.networking.private_subnets)
  vpc_id            = aws_vpc.fiap-vpc.id
  cidr_block        = var.networking.private_subnets[count.index]
  availability_zone = var.networking.azs[count.index]

  map_public_ip_on_launch = false

  tags = {
    # "Name"                                      = "private-subnet-${count.index}"
    "kubernetes.io/role/internal-elb"                    = 1
    "kubernetes.io/cluster/${var.cluster_config.name}" = "owned"
  }
}

/* Public Subnets */
resource "aws_subnet" "public-subnet" {
  count             = var.networking.public_subnets == null || var.networking.public_subnets == "" ? 0 : length(var.networking.public_subnets)
  vpc_id            = aws_vpc.fiap-vpc.id
  cidr_block        = var.networking.public_subnets[count.index]
  availability_zone = var.networking.azs[count.index]

  map_public_ip_on_launch = true

  tags = {
    # "Name"                                      = "public-subnet-${count.index}"
    "kubernetes.io/role/elb"                    = 1
    "kubernetes.io/cluster/${var.cluster_config.name}" = "owned"
  }
}

# PUBLIC ROUTE TABLE
resource "aws_route_table" "public-table" {
  vpc_id = aws_vpc.fiap-vpc.id
}

resource "aws_route" "public-routes" {
  route_table_id         = aws_route_table.public-table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.fiap-vpc-igw.id
}

resource "aws_route_table_association" "assoc-public-routes" {
  count          = length(var.networking.public_subnets)
  subnet_id      = aws_subnet.public-subnet[count.index].id
  route_table_id = aws_route_table.public-table.id
}

# PRIVATE ROUTE TABLES
resource "aws_route_table" "private-tables" {
  count  = length(var.networking.azs)
  vpc_id = aws_vpc.fiap-vpc.id
}

resource "aws_route" "private_routes" {
  count                  = length(var.networking.private_subnets)
  route_table_id         = aws_route_table.private-tables[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nats[count.index].id
}

resource "aws_route_table_association" "assoc-private-routes" {
  count          = length(var.networking.private_subnets)
  subnet_id      = aws_subnet.private-subnet[count.index].id
  route_table_id = aws_route_table.private-tables[count.index].id
}

# SECURITY GROUPS
resource "aws_security_group" "fiap-sec-groups" {
  for_each    = { for sec in var.security_groups : sec.name => sec }
  name        = each.value.name
  description = each.value.description
  vpc_id      = aws_vpc.fiap-vpc.id

  dynamic "ingress" {
    for_each = try(each.value.ingress, [])
    content {
      description      = ingress.value.description
      from_port        = ingress.value.from_port
      to_port          = ingress.value.to_port
      protocol         = ingress.value.protocol
      cidr_blocks      = ingress.value.cidr_blocks
      ipv6_cidr_blocks = ingress.value.ipv6_cidr_blocks
    }
  }

  dynamic "egress" {
    for_each = try(each.value.egress, [])
    content {
      description      = egress.value.description
      from_port        = egress.value.from_port
      to_port          = egress.value.to_port
      protocol         = egress.value.protocol
      cidr_blocks      = egress.value.cidr_blocks
      ipv6_cidr_blocks = egress.value.ipv6_cidr_blocks
    }
  }
}

output "vpc-id" {
  value = aws_vpc.fiap-vpc.id
}

output "private-subnets-ids" {
  value = flatten(aws_subnet.private-subnet[*].id)
}
