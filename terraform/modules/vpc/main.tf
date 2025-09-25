# modules/vpc/main.tf
resource "aws_vpc" "app_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = merge(var.common_tags,
  { "Name" = "${var.project_name} ${var.env}" })
}


resource "aws_subnet" "public_app_vpc" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.app_vpc.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]
  tags              = merge(var.common_tags, { "Name" = "app_vpc-public-${var.azs[count.index]}" })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.app_vpc.id
  tags   = var.common_tags
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.app_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = var.common_tags
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public_app)
  subnet_id      = aws_subnet.public_app[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_subnet" "private_app_vpc" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.app_vpc.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]
  tags              = merge(var.common_tags, { "Name" = "app_vpc-private-${var.azs[count.index]}" })
}

# Add NAT Gateway for private subnets (required for outbound internet access)
resource "aws_eip" "app_vpc_nat" {
  count  = length(var.public_subnet_cidrs)
  domain = "vpc"
}

resource "aws_nat_gateway" "app_vpc_nat_gw" {
  count         = length(var.public_subnet_cidrs)
  allocation_id = aws_eip.app_vpc_nat[count.index].id
  subnet_id     = aws_subnet.public_app_vpc[count.index].id
  tags = {
    Name = "${var.env}-nat-${count.index}"
  }
}

resource "aws_route_table" "private" {
  count  = length(var.private_subnet_cidrs)
  vpc_id = aws_vpc.app_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.app_vpc_nat_gw[count.index % length(var.public_subnet_cidrs)].id
  }
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private_app_vpc)
  subnet_id      = aws_subnet.private_app_vpc[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
