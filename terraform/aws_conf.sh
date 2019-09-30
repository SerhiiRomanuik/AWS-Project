#!/bin/bash

sudo apt install python-pip -y
sudo pip install awscli &&
aws configure set aws_access_key_id aaki
aws configure set aws_secret_access_key asak
aws configure set default.region us-east-2
aws configure set default.output table
