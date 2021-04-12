# terraform-infra-automation :rocket:
> Create 3 tire application from scratch using terraform and ansible
 

### Project Structure and deployment files! :sparkles:
* [Ansible Roles](ansible)
* [Ansible Mongodb role](ansible/ansible-role-mongodb)
* [Ansible node.js role](ansible/ansible-role-nodejs)  
* [Ansible nginx role](ansible/ansible-role-nginx)   
* [AWS VPC terraform module](aws-module)

### Trigger terraform
```shell
git clone https://github.com/soumyarout80/terraform-infra-automation.git
cd terraform-infra-automation/aws-module
terraform init
terraform validate
terraform plan
terraform apply
```

### Configure Mongodb using Ansible
```shell
cd terraform-infra-automation/ansible
ansible-playbook -i inventory mongo-db.yml
```

## License

See the [LICENSE](LICENSE) file for license rights and limitations (MIT).

### Author
> **Name**: Soumya Ranjan Rout

> **Email**: soumyarout80@gmail.com