# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.ssh.guest_port = "2222"
  config.vm.box = "debian/buster64"
  config.vm.box_version = "10.20210409.1"
  config.vm.network "private_network", type: "dhcp"
  config.vm.synced_folder '.', '/vagrant', disabled: true
  config.vm.provider "virtualbox" do |v|
    v.memory = 1024
    v.cpus = 1
  end
  config.vm.provision "shell", inline: <<-SHELL
SHELL
end
