# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "debian/buster64"
  #config.vm.box_version = "2011.0"
  config.vm.network "private_network", type: "dhcp"
  config.vm.provider "virtualbox" do |v|
    v.memory = 1024
    v.cpus = 1
  end
  config.vm.provision "shell", inline: <<-SHELL
    echo shell
    apt-get install -y git python3 python3-pip
    pip3 install ansible yamllint
    if [ ! -d /home/vagrant/ansible ] ; then git clone https://github.com/scottcressi/ansible.git ; fi
SHELL
end
