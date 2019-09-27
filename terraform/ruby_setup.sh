#!/bin/bash

##############################################################
# Installation and configuration for Ruby app.
# Dest of Ruby app: /root/git/Ruby/
##############################################################
# Additional commands:
# rake db:create DATABASE_PASSWORD='password' RAILS_ENV=test
##############################################################

sudo su
sudo yum install -y git libxml2-devel libcurl-devel postgresql-devel postgresql-libs
curl -s https://packagecloud.io/install/repositories/libv8/dev/script.rpm.sh | sudo bash
curl -sSL https://rvm.io/mpapis.asc | gpg2 --import -
curl -sSL https://rvm.io/pkuczynski.asc | gpg2 --import -
curl -L get.rvm.io | bash -s stable
source ~/.rvm/scripts/rvm
rvm reload
rvm install "ruby-2.2.2"
yum install postgresql-server postgresql-contrib -y
sudo postgresql-setup initdb ; systemctl start postgresql ; systemctl enable postgresql
mkdir git/ ; cd git/ ; git init ; git clone https://github.com/SerhiiRomanuik/Ruby_Travis.git ; cd Ruby_Travis
cd /home/ec2-user ; sudo chown -R ec2-user:ec2-user * ; cd git/Ruby_Travis
bin/rake db:migrate RAILS_ENV=test
bin/rake db:migrate RAILS_ENV=development 
bundle install
nohup bash RUN.sh &>/dev/null &