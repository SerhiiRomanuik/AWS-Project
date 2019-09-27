provider "aws" {
  version                 = "~> 2.0"
  region                  = var.region
  shared_credentials_file = var.cred_path
}


################################
## Network setup
################################

resource "aws_vpc" "vpc1" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"
  tags = {
    Name = "VPC-TERRAFORM"
  }
}

resource "aws_subnet" "pub_1" {
  assign_ipv6_address_on_creation = false
  availability_zone               = var.az[0]
  cidr_block                      = var.pub_1_cidr
  map_public_ip_on_launch         = true
  tags = {
    Name = "SubNet-A-TERRAFORM"
  }

  vpc_id = "${aws_vpc.vpc1.id}"
}

resource "aws_subnet" "pub_2" {
  assign_ipv6_address_on_creation = false
  availability_zone               = var.az[1]
  cidr_block                      = var.pub_2_cidr
  map_public_ip_on_launch         = true
  tags = {
    Name = "SubNet-A-TERRAFORM"
  }

  vpc_id = "${aws_vpc.vpc1.id}"
}

resource "aws_subnet" "priv-1" {
  assign_ipv6_address_on_creation = false
  availability_zone               = var.az[0]
  cidr_block                      = var.priv_1_cidr
  tags = {
    Name = "SubNet-B-TERRAFORM-PRIVATE"
  }
  vpc_id = "${aws_vpc.vpc1.id}"
}

resource "aws_subnet" "priv-2" {
  assign_ipv6_address_on_creation = false
  availability_zone               = var.az[1]
  cidr_block                      = var.priv_2_cidr
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
    cidr_block = var.cidr_all
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


##########################################
## Security group: 
## Inbound: 80, 443, 22, ALL Trafic
## Outbound: ALL Trafic
##########################################

resource "aws_security_group" "sg_db" {
  name = "SG-TERRAFORM-DB"
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["${var.sg_cidr}"]
  }
  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["${var.sg_cidr}"]
  }
  vpc_id = "${aws_vpc.vpc1.id}"
  tags = {
    Name = "SG-TERRAFORM-DB"
  }
}


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
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${var.sg_cidr}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${var.sg_cidr}"]
  }
  vpc_id = "${aws_vpc.vpc1.id}"
  tags = {
    Name = "SG-TERRAFORM"
  }
}


####################################
## Launch configuration
####################################

resource "aws_launch_configuration" "lunch" {
  name_prefix     = "Ruby-"
  image_id        = var.ami
  instance_type   = var.inst_type
  security_groups = ["${aws_security_group.sg.id}"]
  key_name        = var.key
  lifecycle {
    create_before_destroy = true
  }
}


####################################
## Autoscaling Group for Instances
####################################

resource "aws_autoscaling_group" "asg" {
  name                 = "ASG-TERRAFORM"
  launch_configuration = "${aws_launch_configuration.lunch.id}"
  availability_zones   = var.az
  vpc_zone_identifier  = ["${aws_subnet.pub_1.id}", "${aws_subnet.pub_2.id}"]
  min_size             = 3
  desired_capacity     = 3
  max_size             = 4
  load_balancers       = ["${aws_elb.app_elb.name}"]
  health_check_type    = "ELB"
  tag {
    key                 = "Name"
    value               = "Terraform"
    propagate_at_launch = true
  }
}



#############################################
## Application ELB (with own Security group)
#############################################

resource "aws_security_group" "sg_elb" {
  name   = "Security group for ELB"
  vpc_id = "${aws_vpc.vpc1.id}"
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.cidr_all]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.cidr_all]
  }
}

resource "aws_elb" "app_elb" {
  name = "application-lb"
  subnets                   = ["${aws_subnet.pub_1.id}", "${aws_subnet.pub_2.id}"]
  security_groups           = ["${aws_security_group.sg_elb.id}"]
  cross_zone_load_balancing = true
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    target              = "HTTP:90/"
  }
  listener {
    lb_port           = 80
    lb_protocol       = "http"
    instance_port     = "90"
    instance_protocol = "http"
  }
}

resource "aws_elb_attachment" "elb_atach" {
  count    = var.inst_count
  elb      = "${aws_elb.app_elb.id}"
  instance = "${element(aws_instance.inst1.*.id, count.index)}"
  # "${aws_instance.inst1.[count.index].id}"
}


################################
## Application servers setup
################################

resource "aws_instance" "inst1" {
  count                       = var.inst_count
  availability_zone           = var.az[0]
  ami                         = var.ami
  key_name                    = var.key
  instance_type               = var.inst_type
  subnet_id                   = aws_subnet.pub_1.id
  vpc_security_group_ids      = [aws_security_group.sg.id]
  associate_public_ip_address = true
  source_dest_check           = false
  # user_data                   = var.user_data
  tags = {
    Name = "Terraform"
  }
}

# module "ec2_cluster" {
#  source = "terraform-aws-modules/ec2-instance/aws"
#  name           = "my-cluster"
#  instance_count = var.inst_count
#  ami                    = var.ami
#  instance_type          = var.inst_type
#  key_name               = var.key
#  monitoring             = true
#  associate_public_ip_address = true
#  source_dest_check = false
#  vpc_security_group_ids = [aws_security_group.sg.id]
#  subnet_id              = aws_subnet.pub_2.id
#  tags = {
#    Name = "Applcation"
# }
# }



######################################################
## RDS, based on PostgreSQL
######################################################

module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 2.0"
  identifier = "db"
  engine            = "postgres"
  engine_version    = "10"
  instance_class    = "db.t2.micro"
  allocated_storage = 5

  name     = "ruby"
  username = "root"
  password = "password"
  port     = "5432"

  iam_database_authentication_enabled = true
  vpc_security_group_ids = [aws_security_group.sg_db.id]
  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"
 # monitoring_interval = "30"
  monitoring_role_name = "MyRDSMonitoringRole"
  create_monitoring_role = true
  family = "postgres10"

  tags = {
    Owner       = "user"
    Environment = "dev"
  }
  subnet_ids = [aws_subnet.priv-1.id,aws_subnet.priv-2.id]
  deletion_protection = false
}