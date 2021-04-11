#!/bin/sh
##### Instance ID captured through Instance meta data #####
InstanceID=`/usr/bin/curl -s http://169.254.169.254/latest/meta-data/instance-id`
##### Set a tag name indicating instance is not configured ####
aws ec2 create-tags --region $EC2_REGION --resources $InstanceID --tags Key=Initialized,Value=false
##### Install Ansible ######
apt-get update
apt-get install -y git wget
curl "https://bootstrap.pypa.io/get-pip.py" -o "/tmp/get-pip.py"
python /tmp/get-pip.py
pip install pip --upgrade
rm -fr /tmp/get-pip.py
pip install boto
pip install --upgrade ansible
##### Clone your ansible repository ######
git clone https://github.com/soumyarout80/terraform-infra-automation.git
cd terraform-infra-automation/ansible
#chmod 400 keys/*
##### Run your ansible playbook for only autoscaled and not initialised instances ######
ansible-playbook --connection=local --inventory 127.0.0.1 nginx-web-server.yml --limit "tag_Name_AutoScaled:&tag_Initialized_false"
##### Update TAG ######
aws ec2 create-tags --region $EC2_REGION --resources $InstanceID --tags Key=Initialized,Value=true