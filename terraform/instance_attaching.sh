#!/bin/bash


find output || mkdir output
terraform output instance_id > output/output
string1=`sed -n '2p' output/output`
string2=`sed -n '3p' output/output`
inst_1=`echo ${string1:3:-2}`                # > id_dir/id_inst
inst_2=`echo ${string2:3:-2}`                # >> id_dir/id_inst

## PRE-INSTALLED PIP > AWS-CLI

aws autoscaling attach-instances --instance-ids $inst_1 --auto-scaling-group-name ASG-TERRAFORM
aws autoscaling attach-instances --instance-ids $inst_2 --auto-scaling-group-name ASG-TERRAFORM
