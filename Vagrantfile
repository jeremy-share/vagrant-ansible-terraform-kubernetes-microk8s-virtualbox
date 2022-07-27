# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # https://docs.vagrantup.com.

  config.vm.provider "virtualbox" do |vb|
     # Customize the amount of memory on the VM:
     vb.name = "test-microk8s"
     vb.memory = "4096"
     vb.cpus = 2
     vb.customize ["modifyvm", :id, "--cpuexecutioncap", "80"]
  end

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://vagrantcloud.com/search.
  config.vm.box = "ubuntu/focal64"  # 20.04 LTS

  # Hard coded MAC so we get the same IP each time
  # If this does not work, your DHCP may be looking at network UID (setting on DHCP)
  config.vm.network "public_network", bridge: "wlp2s0", :mac => "080027425294"

  config.vm.hostname = "test-microk8s"

  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "ansible-playbook.yml"
  end

  # Restart once done, so the hostname takes effect
  config.vm.provision "shell", inline: <<-SHELL
    shutdown -r now
  SHELL
end
