Vagrant.configure("2") do |config|
  config.vagrant.plugins = ["vagrant-hosts", "vagrant-env", "vagrant-reload"]
  config.env.enable
  config.vm.define "dev" do |subconfig|
    subconfig.vm.box = ENV['VAGRANT_BOX']
    subconfig.vm.box_check_update = true
    subconfig.vm.hostname = ENV["DOMAIN"]
    subconfig.vm.network "private_network", ip: ENV["VAGRANT_IP"]
    subconfig.vm.synced_folder ".", "/home/vagrant/src"
    subconfig.ssh.forward_agent = true
    subconfig.vm.provider "virtualbox" do |vb|
      vb.name = ENV["PROJECT_NAME"]
      vb.gui = false
      vb.cpus = ENV["VAGRANT_CPUS"]
      vb.memory = ENV["VAGRANT_MEMORY"]
    end
    subconfig.vm.provision :hosts do |provisioner|
      provisioner.add_host ENV["VAGRANT_IP"], [ENV["DOMAIN"]]
    end
    # subconfig.vm.provision :ansible do |ansible|
    #   ansible.limit = "all"
    #   ansible.playbook = "config/ansible/dependencies.playbook.yml"
    #   ansible.extra_vars = {primary_ssh_user: "vagrant"}
    # end
    # config.vm.provision :reload
    subconfig.vm.provision :ansible do |ansible|
      ansible.limit = "all"
      ansible.playbook = "config/ansible/deploy-traefik.playbook.yml"
      ansible.extra_vars = {primary_ssh_user: "vagrant"}
    end
  end
end
