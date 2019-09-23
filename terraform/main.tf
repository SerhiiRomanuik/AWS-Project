provider "aws" {
  version                 = "~> 2.0"
  region                  = "${var.region}"
  shared_credentials_file = "${var.cred_path}"
}

data "template_file" "tpl1" {
  template = "${var.dest1}"
}
data "template_file" "tpl2" {
  template = "${var.dest2}"
}

# data "template_file" "tpl3" {
#   template = "${var.dest3}"
# }

# data "template_file" "example" {
#   template = "$${arg}:port"
#   vars {
#     arg = "${aws_... .ip}"
#   }
# }