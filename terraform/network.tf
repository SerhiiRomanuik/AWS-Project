################################
## Network setup
################################
## NETWORK.PLAN
## terraform plan -target=aws_route_table_association.rtb1 -target=aws_route_table_association.rtb2 -target=aws_subnet.priv-1 -target=aws_subnet.priv-2 -out 1net.plan && terraform apply 1net.plan
resource "aws_vpc" "vpc1" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"
  tags = {
    Name = "VPC-TERRAFORM"
  }
}

resource "aws_subnet" "pub_1" {
  assign_ipv6_address_on_creation = false
  availability_zone               = "${var.az[0]}"
  cidr_block                      = "${var.pub_1_cidr}"
  map_public_ip_on_launch         = true
  tags = {
    Name = "SubNet-A-TERRAFORM"
  }

  vpc_id = "${aws_vpc.vpc1.id}"
}

resource "aws_subnet" "pub_2" {
  assign_ipv6_address_on_creation = false
  availability_zone               = "${var.az[1]}"
  cidr_block                      = "${var.pub_2_cidr}"
  map_public_ip_on_launch         = true
  tags = {
    Name = "SubNet-A-TERRAFORM"
  }

  vpc_id = "${aws_vpc.vpc1.id}"
}

resource "aws_subnet" "priv-1" {
  assign_ipv6_address_on_creation = false
  availability_zone               = "${var.az[0]}"
  cidr_block                      = "${var.priv_1_cidr}"
  tags = {
    Name = "SubNet-B-TERRAFORM-PRIVATE"
  }
  vpc_id = "${aws_vpc.vpc1.id}"
}

resource "aws_subnet" "priv-2" {
  assign_ipv6_address_on_creation = false
  availability_zone               = "${var.az[1]}"
  cidr_block                      = "${var.priv_2_cidr}"
  tags = {
    Name = "SubNet-C-TERRAFORM-PRIVATE"
  }
  vpc_id = "${aws_vpc.vpc1.id}"
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.vpc1.id}"
  tags = {
    Name = "IGW-TERRAFORM"
  }
}

resource "aws_route_table" "rtb" {
  vpc_id = "${aws_vpc.vpc1.id}"
  route {
    cidr_block = "${var.cidr_all}"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }
  tags = {
    Name = "Route-TERRAFORM"
  }
}

resource "aws_route_table_association" "rtb1" {
  subnet_id      = "${aws_subnet.pub_1.id}"
  route_table_id = "${aws_route_table.rtb.id}"
}

resource "aws_route_table_association" "rtb2" {
  subnet_id      = "${aws_subnet.pub_2.id}"
  route_table_id = "${aws_route_table.rtb.id}"
}
