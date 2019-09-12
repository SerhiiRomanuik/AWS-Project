variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "a_z" {
  default = "us-east-2"
}

variable "ami" {
  default = "ami-00c03f7f7f2ec15c3"
}

#variable "key" {
#  default = "key-pair2.pub"
#}

variable "inst_type" {
  default = "t2.micro"
}

variable "user_data"{
  default = "./.script"
}

#variable "inst_count"{
#  default = 2
#}
