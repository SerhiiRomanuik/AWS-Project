################################
## Application servers setup
################################
## Etc, script: command $1
## aws autoscaling attach-instances --instance-ids [id] --auto-scaling-group-name ASG-TERRAFORM
###############################
## EC2.PLAN >> INST.PLAN
## terraform plan -target=aws_instance.inst1 -target=aws_security_group.sg_db -target=aws_launch_configuration.lunch -target=aws_autoscaling_group.asg -target=aws_security_group.sg_elb -target=aws_elb.app_elb -out 4ec2.plan  && terraform apply 4ec2.plan

resource "aws_instance" "inst1" {
  count                       = "${var.inst_count}"
  private_ip                  = "10.0.1.1${count.index}"
  availability_zone           = "${var.az[0]}"
  ami                         = "${var.ami}"
  key_name                    = "${var.key}"
  instance_type               = "${var.inst_type}"
  subnet_id                   = "${aws_subnet.pub_1.id}"
  vpc_security_group_ids      = ["${aws_security_group.sg.id}"]
  associate_public_ip_address = "${var.public_addr}"
  source_dest_check           = false
  tags = {
    Name = "Terraform"
  }
}
#
# resource "null_resource" "for_instance" {
#     triggers = {
#       cluster_instance_ids = "${join(",", aws_instance.inst1.*.id)}"
#     }
#     provisioner "local-exec" {
#    command = "${data.template_file.tpl2.template}"
#  }
# }

###############################################
## Security group:
## Inbound: 80, 443, 22, ALL Trafic (5432 DB)
## Outbound: ALL Trafic (5432 DB)
###############################################

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
  image_id        = "${var.ami}"
  instance_type   = "${var.inst_type}"
  security_groups = ["${aws_security_group.sg.id}"]
  key_name        = "${var.key}"
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
  availability_zones   = "${var.az}"
  vpc_zone_identifier  = ["${aws_subnet.pub_1.id}", "${aws_subnet.pub_2.id}"]
  min_size             = 0
  desired_capacity     = 0
  max_size             = 3
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
    cidr_blocks = ["${var.cidr_all}"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${var.cidr_all}"]
  }
}

resource "aws_elb" "app_elb" {
  name                      = "application-lb"
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

# resource "aws_elb_attachment" "elb_atach" {
#   count    = "${var.inst_count}"
#   elb      = "${aws_elb.app_elb.id}"
#   instance = "${element(aws_instance.inst1.*.id, count.index)}"
#   # "${aws_instance.inst1.[count.index].id}"
# }
