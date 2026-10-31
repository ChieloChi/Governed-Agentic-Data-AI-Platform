# Data source for AZs in the selected region
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC Definition
resource "aws_vpc" "ai_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name                                           = "${var.cluster_name}-vpc"
    "kubernetes.io/cluster/${var.cluster_name}"   = "shared"
  }
}

# Internet Gateway for direct outbound connectivity (Zero NAT Gateway charges!)
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.ai_vpc.id

  tags = {
    Name = "${var.cluster_name}-igw"
  }
}

# Public Subnet 1
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.ai_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name                                           = "${var.cluster_name}-public-1"
    "kubernetes.io/cluster/${var.cluster_name}"   = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }
}

# Public Subnet 2
resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.ai_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name                                           = "${var.cluster_name}-public-2"
    "kubernetes.io/cluster/${var.cluster_name}"   = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }
}

# Route Table for Public Subnets
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.ai_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.cluster_name}-public-rt"
  }
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public_rt.id
}

