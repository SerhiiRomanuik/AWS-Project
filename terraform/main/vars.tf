variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "region" {
  default = "us-east-2"
}

variable "ami" {
  default = "ami-00c03f7f7f2ec15c3"
}

variable "key" {
  default = "key-pair"
}

variable "inst_type" {
  default = "t2.micro"
}

variable "user_data"{
  default = "./.script"
}

variable "inst_count"{
  default = "2"
}

variable "sg_cidr"{
  default = "0.0.0.0/0"
}

variable "amis" {
  default = {
  us-east-2 = "ami-00c03f7f7f2ec15c3"
  }
}
