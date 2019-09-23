#!/bin/bash

find id_dir || mkdir id_dir
terraform output > id_dir/id_inst
string1=`sed -n '2p' id_dir/id_inst`
string2=`sed -n '3p' id_dir/id_inst`
inst_1=`echo ${string1:3:-2}`                # > id_dir/id_inst
inst_2=`echo ${string2:3:-2}`                # >> id_dir/id_inst

aws autoscaling attach-instances --instance-ids $inst_1 --auto-scaling-group-name ASG-TERRAFORM
aws autoscaling attach-instances --instance-ids $inst_2 --auto-scaling-group-name ASG-TERRAFORM
