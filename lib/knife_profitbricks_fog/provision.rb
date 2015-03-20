module KnifeProfitbricksFog
  module Provision

    private
    def bootstrap_or_cook
      command = "dpkg -l | grep chef | awk '{print $3}' | egrep -o '([0-9]+\\.)+[0-9]+'"
      version = `ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no #{Chef::Config[:knife][:ssh_user]}@#{server_ip} "#{command}"`.strip

      log "Chef version on server '#{server_name}': #{version}"
      log "Local chef version: #{Chef::VERSION}"
      
      chef_klass = if version == Chef::VERSION
        cook
      else
        bootstrap
      end
      
      chef_klass.load_deps
      chef = chef_klass.new
      chef.name_args = [server_ip]
      chef.config[:run_list] = Chef::Config[:knife][:run_list] if Chef::Config[:knife][:run_list]
      chef.config[:ssh_user] = Chef::Config[:knife][:ssh_user]
      chef.config[:host_key_verify] = false
      chef.config[:chef_node_name] = Chef::Config[:knife][:chef_node_name]
      #chef.config[:use_sudo] = true unless bootstrap.config[:ssh_user] == 'root'
      chef.config[:sudo_command] = "echo #{Shellwords.escape(user_password)} | sudo -ES" if @server_is_new
      chef.run
    end

    def bootstrap
      log "Boostrap server..."
      Chef::Knife::SoloBootstrap
    end

    def cook
      log "Cook server..."
      Chef::Knife::SoloCook
    end

    def add_server_to_known_hosts__if_new
      if @server_is_new
        node = Chef::Config[:knife][:chef_node_name]

        system("ssh-keygen -R #{server_ip}")
        system("ssh-keygen -R #{node}") if node

        system("ssh-keyscan #{server_ip} >> #{ENV['HOME']}/.ssh/known_hosts")
        system("ssh-keyscan #{node} >> #{ENV['HOME']}/.ssh/known_hosts") if node
      end
    end

    def reboot_server__if_new
      if @server_is_new
        user_and_server = "#{Chef::Config[:knife][:ssh_user]}@#{server_ip}"

        system("ssh #{user_and_server} 'sudo reboot'")
      end
    end
  end
end
