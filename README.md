# Vagrant Ansible Terraform Kubernetes MicroK8s VirtualBox
All the things above in one repo as an example.
See [LICENSE](LICENSE) file. Repo is as is where is. For example only and not for production!

## About
Random thing I built and wanted to share how to connect everything together as it might help someone.

## Notes
* Only tested on Linux (Ubuntu 22.04 LTS)
* You may want to add an entry into your DNS for the VM. Mac: `08:00:27:42:52:94` Host: `test-microk8s`
* This repo assumes you have a `id_ed25519.pub` key

## Running
Checkout the [Makefile](Makefile) for details and commands

### Command: `make up`
1. Creates a VirtualBox VM with Vagrant [Vagrantfile](Vagrantfile)
   1. Bridges it to your network (auto tries wlp2s0 adaptor)
2. Auto provisions it with Ansible (using Vagrant provisioner) [ansible-playbook.yml](ansible-playbook.yml)
   1. Install a MicroK8s Kubernetes cluster and enables k8 modules
   2. Adds your user to the machine with SSH key and sudo without password
3. Restarts the machine (using Vagrant provisioner) [Vagrantfile](Vagrantfile)
4. Downloads `kubeconfig.yml`
5. Runs Terraform to provision a simple HTTP container [terraform.tf](terraform.tf)

### Links
* [http://test-microk8s](http://test-microk8s)
* [http://test-microk8s/app-1](http://test-microk8s/app-1)
* [http://test-microk8s/app-2](http://test-microk8s/app-2)

### Command: `make down`
1. Destroys the Virtual machine
