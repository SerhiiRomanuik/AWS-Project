  provider "aws"{
  version = "~> 2.0"
  region = var.region
  shared_credentials_file = "/root/terraform/main/.aws/credentials"
}

data "aws_availability_zones" "all" {}

################################
## Network setup
################################


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
          "Name" = "SubNet-A-TERRAFORM"
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

##########################################
## Security group: 
## Inbound: 80, 443, 22, ALL Trafic
## Outbound: ALL Trafic
##########################################

resource "aws_security_group" "sg" {
  name = "SG-TERRAFORM-PUBLIC"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${var.sg_cidr}"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["${var.sg_cidr}"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.sg_cidr}"]
 }
 ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["${var.sg_cidr}"]
  }

 egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["${var.sg_cidr}"]
  }
  vpc_id = "${aws_vpc.vpc1.id}"
  tags   = {
    Name = "SG-TERRAFORM"
  }
}

####################################
## Launch configuration
####################################

resource "aws_launch_configuration" "lunch" {
  image_id               = "${lookup(var.amis,var.region)}"
  instance_type          = var.inst_type
  security_groups        = ["${aws_security_group.sg.id}"]
  key_name               = var.key
  lifecycle {
    create_before_destroy = true
  }
}


####################################
## Autoscaling Group for Instances
####################################

resource "aws_autoscaling_group" "asg" {
  launch_configuration = "${aws_launch_configuration.lunch.id}"
  availability_zones = "${data.aws_availability_zones.all.names}"
  min_size = 2
  max_size = 6
  load_balancers = ["${aws_elb.app_elb.name}"]
  health_check_type = "ELB"
  tag {
    key = "Name"
    value = "Terraform"
    propagate_at_launch = true
  }
}


#############################################
## Application ELB (with own Security group)
#############################################

resource "aws_security_group" "sg_elb" {
  name = "Security group for ELB"
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_elb" "app_elb" {
  name = "application-lb"
  security_groups = ["${aws_security_group.sg_elb.id}"]
  availability_zones = "${data.aws_availability_zones.all.names}"
  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    interval = 30
    target = "HTTP:90/"
  }
  listener {
    lb_port = 80
    lb_protocol = "http"
    instance_port = "90"
    instance_protocol = "http"
  }
}


################################
## Application servers setup
################################

resource "aws_instance" "inst1" {
   availability_zone = "us-east-2a"
   ami  = var.ami
   key_name = var.key
   instance_type = var.inst_type
   subnet_id = aws_subnet.pub_1.id
   vpc_security_group_ids = [aws_security_group.sg.id]
   associate_public_ip_address = true
   source_dest_check = false
   user_data = var.user_data
   tags = {
     Name = "Terraform"
  }
}

module "ec2_cluster" {
  source = "terraform-aws-modules/ec2-instance/aws"
  name           = "my-cluster"
  instance_count = var.inst_count
  ami                    = var.ami
  instance_type          = var.inst_type
  key_name               = var.key
  monitoring             = true
  associate_public_ip_address = true
  source_dest_check = false
  vpc_security_group_ids = [aws_security_group.sg.id]
  subnet_id              = aws_subnet.pub_1.id
  tags = {
    Name = "Applcation"
 }
}
