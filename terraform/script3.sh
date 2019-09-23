#!/bin/bash

sudo apt-add-repository ppa:ansible/ansible -y ; sudo apt update -y
sudo apt install ansible git -y
mkdir git/
cd git/
git init
git clone https://github.com/SerhiiRomanuik/Ansible.git
cd Ansible/
sudo cp playbook.yml /etc/ansible
cd /etc/ansible
ansible-playbook playbook.yml  