########################################
## Jenkins setup with Ansible-playbook
########################################
## JENKINS.PLAN
## terraform plan -target=aws_instance.jenkins -out 2jen.plan
resource "aws_instance" "jenkins" {
  availability_zone           = "${var.az[0]}"
  ami                         = "${var.ami_ub}"
  key_name                    = "${var.key}"
  instance_type               = "${var.inst_type}"
  subnet_id                   = "${aws_subnet.pub_1.id}"
  vpc_security_group_ids      = ["${aws_security_group.sg.id}"]
  associate_public_ip_address = "${var.public_addr}"
  source_dest_check           = false
  # user_data                   = "${data.template_file.tpl3.rendered}"
  tags = {
    Name = "Jenkins"
  }
#   provisioner "file" {
#     source      = "./script3.sh"
#     destination = "/home/ubuntu/script3.sh"
#   }
#     connection {
#       type        = "ssh"
#       user        = "ubuntu"
#       private_key = "${file("${var.pr_key}")}"
#       host        = "${aws_instance.jenkins.public_ip}"
#     }
  
#   provisioner "remote-exec" {
#     inline = ["bash /home/ubuntu/script3.sh"]
#    }
 }