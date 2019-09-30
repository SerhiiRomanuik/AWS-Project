variable "cred_path" {
  default = ".aws/credentials"
}

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

variable "user_data" {
  default = ".script"
}

variable "inst_count"{
 default = "2"
}

variable "sg_cidr" {
  default = "0.0.0.0/0"
}

variable "az" {
  type    = "list"
  default = ["us-east-2a", "us-east-2b", "us-east-2c"]
}

variable "cidr_all" {
  default = "0.0.0.0/0"
}

variable "pub_1_cidr" {
  default = "10.0.1.0/24"
}

variable "pub_2_cidr" {
  default = "10.0.2.0/24"
}

variable "priv_1_cidr" {
  default = "10.0.3.0/24"
}

variable "priv_2_cidr" {
  default = "10.0.4.0/24"
}

variable "ami_ub" {
  default = "ami-05c1fa8df71875112"
}

variable "public_addr"{
  default = true
}

variable "ruby_setup"{
  default = "/home/serhii/terraform/ruby_setup.sh"
}

variable "endpoint" {
  default = "/home/serhii/terraform/script_endpoint.sh"
}

variable "inst_attach"{
  default = "/home/serhii/terraform/instance_attaching.sh"
}

variable "pr_key"{
  default = "./key-pair.pem"
}
