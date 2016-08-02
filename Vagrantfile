# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|

  config.vm.provider :virtualbox do |vb|
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
    vb.customize ["modifyvm", :id, "--memory", 2048]
    vb.customize ["modifyvm", :id, "--cpus", 2]
  end

  config.vm.box = "ubuntu/trusty64"

  config.vm.provision :shell, inline: <<-SHELL
    if [ ! -f ~/.runonce ]
    then
      sudo apt-get install --reinstall -y language-pack-en
      sudo locale-gen "en_US.UTF-8"
      sudo dpkg-reconfigure locales
      echo 'LC_ALL="en_US.UTF-8"' | sudo tee -a /etc/default/locale
      echo 'LANG="en_US.UTF-8"' | sudo tee -a /etc/default/locale
      touch ~/.runonce
    fi
  SHELL

  #-----------------Network
  # App server
  config.vm.network :forwarded_port, guest: 9292, host: 9292

end
