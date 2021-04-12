#!/bin/sh
##### Install Ansible ######
apt-get update
apt-get install -y git wget ansible

##### Clone your ansible repository ######
git clone https://github.com/soumyarout80/terraform-infra-automation.git
cd terraform-infra-automation/ansible

##### Run your ansible playbook for only autoscaled and not initialised instances ######
ansible-playbook --connection=local --inventory 127.0.0.1, node-ansible-role.yml