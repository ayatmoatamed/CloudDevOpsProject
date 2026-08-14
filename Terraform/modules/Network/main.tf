resource "aws_vpc" "ivolve_vpc" {

  cidr_block = var.vpc_cidr

  tags = {
    Name = "ivolve_vpc" 
}

}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.ivolve_vpc.id

  tags = {
    Name = "ivolve_igw"
  }

}

resource "aws_subnet" "public_subnet" {
  vpc_id = aws_vpc.ivolve_vpc.id

  cidr_block = var.public_subnet_cidr

  map_public_ip_on_launch = true

  tags = {
    Name = "ivolve_public_subnet"
  }
  
}

# ======================================================================

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.ivolve_vpc.id

  route {
     cidr_block = "0.0.0.0/0"
     gateway_id = aws_internet_gateway.igw.id

  }
  tags = {
    Name = "ivolve-public-route-table"
  }

}


resource "aws_route_table_association" "public_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_subnet" "private_subnet_1" {
  vpc_id = aws_vpc.ivolve_vpc.id

  cidr_block = var.private_subnet_cidrs[0]

  availability_zone = var.private_subnet_azs[0]

  tags = {
    Name = "ivolve-private-subnet-1"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id = aws_vpc.ivolve_vpc.id

  cidr_block = var.private_subnet_cidrs[1]

  availability_zone = var.private_subnet_azs[1]

  tags = {
    Name = "ivolve-private-subnet-2"
  }
}
# =====================================================================

resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name = "ivolve-nat-eip"
  }
}
# =======================================================================

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id

  tags = {
    Name = "ivolve-nat"
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.ivolve_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "ivolve-private-route-table"
  }
}

resource "aws_route_table_association" "private_association_1" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_association_2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_route_table.id
}

# ============================================================
# Public NACL
resource "aws_network_acl" "public_nacl" {
  vpc_id     = aws_vpc.ivolve_vpc.id
  subnet_ids = [aws_subnet.public_subnet.id]

  ingress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "ivolve-public-nacl"
  }
}

# ================================================================================
# Private NACL
resource "aws_network_acl" "private_nacl" {
  vpc_id     = aws_vpc.ivolve_vpc.id
  subnet_ids = [
    aws_subnet.private_subnet_1.id,
    aws_subnet.private_subnet_2.id
  ]

  ingress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "10.0.0.0/16"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  egress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "ivolve-private-nacl"
  }
}