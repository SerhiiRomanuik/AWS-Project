#!/bin/bash

cd terraform/
terraform init || bash ../install_terr
sed -i "s/aaki/"${ACCESS_KEY}"/" .aws/credentials
sed -i "s/aaki/"${ACCESS_KEY}"/" aws_conf.sh
sed -i "s/asak/"${SECRET_KEY}"/" .aws/credentials
sed -i "s/asak/"${SECRET_KEY}"/" aws_conf.sh
aws --version || bash aws_conf.sh
terraform destroy -target=module.db -target=aws_instance.inst1 -target=aws_security_group.sg_db -target=aws_launch_configuration.lunch -target=aws_autoscaling_group.asg -target=aws_security_group.sg_elb -target=aws_elb.app_elb -auto-approve
terraform plan -target=module.db -out 3dat.plan && terraform apply 3dat.plan
terraform plan -target=aws_instance.inst1 -target=aws_security_group.sg_db -target=aws_launch_configuration.lunch -target=aws_autoscaling_group.asg -target=aws_security_group.sg_elb -target=aws_elb.app_elb -out 4ec2.plan  && terraform apply 4ec2.plan
terraform refresh
bash instance_attaching.sh
bash script_endpoint.sh
