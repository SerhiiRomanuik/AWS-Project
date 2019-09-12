provider "aws" {
  version = "~> 2.0"
  region = var.a_z
  shared_credentials_file = "/root/terraform/.pass"
}

###################### VPC BLOCK ##########################

resource "aws_vpc" "vpc1" {
       cidr_block                       = var.vpc_cidr
       enable_dns_hostnames             = true 
       enable_dns_support               = true 
       instance_tenancy                 = "default"
       tags                             = {
          "Name" = "VPC-TERRAFORM"
        }
    }

resource "aws_subnet" "pub_1" {
      assign_ipv6_address_on_creation = false
      availability_zone               = "us-east-2a"
      cidr_block                      = "10.0.0.0/24"
      map_public_ip_on_launch         = true
      tags                            = {
          Name = "SubNet-A-TERRAFORM"
        }
      vpc_id                          = "${aws_vpc.vpc1.id}"
    }

resource "aws_subnet" "priv-1" {
      assign_ipv6_address_on_creation = false
      availability_zone               = "us-east-2b"
      cidr_block                      = "10.0.1.0/24"
      tags                            = {
          Name = "SubNet-B-TERRAFORM-PRIVATE"
        }
       vpc_id                          = "${aws_vpc.vpc1.id}"
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
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }
  tags = {
    Name = "Route-TERRAFORM"
  }
}

 resource "aws_route_table_association" "rtb" {
   subnet_id = "${aws_subnet.pub_1.id}"
   route_table_id = "${aws_route_table.rtb.id}"
}

resource "aws_security_group" "sg" {
  name = "SG-TERRAFORM"
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks =  ["0.0.0.0/0"]
  }
 ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
 egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
  vpc_id="${aws_vpc.vpc1.id}"
  tags = {
    Name = "SG-TERRAFORM"
  }
}

######################### INSTANCE BLOCK ##############################

 resource "aws_key_pair" "default" {
   key_name = "keypair"
   public_key = "${tls_private_key.superkey.public_key_openssh}"
 }

resource "tls_private_key" "superkey" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_instance" "inst1" {
   availability_zone = "us-east-2a"
   ami  = var.ami
   key_name = "${aws_key_pair.default.key_name}"
   instance_type = var.inst_type
   subnet_id = aws_subnet.pub_1.id
   vpc_security_group_ids = [aws_security_group.sg.id]
   associate_public_ip_address = true
   source_dest_check = false
   user_data = var.user_data
   tags = {
     Name = "Application-Instance"
  }
}

#module "ec2_cluster" {
#  source                 = "terraform-aws-modules/ec2-instance/aws"
#  version                = "~> 2.0"
#  name                   = "Cluster"
#  instance_count         = "var.inst_count"
#  ami                    = "var.ami"
#  instance_type          = "var.key"
#  key_name               = "aws_key_pair.default.id"
#  monitoring             = true
#  vpc_security_group_ids = ["aws_security_group.sg.id"]
#  subnet_id = "${aws_subnet.pub-1.id}"
#}
