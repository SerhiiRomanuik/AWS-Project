#!/bin/bash

sudo apt-add-repository ppa:ansible/ansible -y ; sudo apt update -y
sudo apt install -y ansible # git
# mkdir git/
# cd git/
# git init
# git clone https://github.com/SerhiiRomanuik/Ansible.git
# cd Ansible/
sudo cp playbook.yml /etc/ansible
cd /etc/ansible
sudo sed -i "s/# some basic default values.../command_warnings=False/" /etc/ansible/ansible.cfg
ansible-playbook playbook.yml
