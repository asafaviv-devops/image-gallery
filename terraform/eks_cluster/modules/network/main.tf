data "aws_availability_zones" "azs" {}

locals {
  prefix = "${var.app_name}-${var.env}"

  common_tags = merge(
    var.tags,
    {
      App       = var.app_name
      Env       = var.env
      ManagedBy = "terraform"
    }
  )
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, {
    Name = "${local.prefix}-vpc"
  })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${local.prefix}-igw"
  })
}

resource "aws_subnet" "public" {
  for_each = {
    for idx, cidr in var.public_subnets_cidrs : idx => cidr
  }

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.azs.names[tonumber(each.key)]

  tags = merge(local.common_tags, {
    Name = "${local.prefix}-public-subnet-${each.key}"
  })
}

resource "aws_subnet" "private" {
  for_each = {
    for idx, cidr in var.private_subnets_cidrs : idx => cidr
  }

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  availability_zone = data.aws_availability_zones.azs.names[tonumber(each.key)]

  tags = merge(local.common_tags, {
    Name = "${local.prefix}-private-subnet-${each.key}"
  })
}

resource "aws_eip" "nat_eip" {
#  vpc = true

  tags = merge(local.common_tags, {
    Name = "${local.prefix}-nat-eip"
  })
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = values(aws_subnet.public)[0].id

  tags = merge(local.common_tags, {
    Name = "${local.prefix}-nat-gw"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${local.prefix}-public-rt"
  })
}

resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_assoc" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${local.prefix}-private-rt"
  })
}

resource "aws_route" "private_route" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "private_assoc" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

