module KnifeProfitbricks
  module SshCommands
    
    def self.included(base)
      base.class_eval do 
        option :profitbricks_authorized_key,
          :short => "-authorized-key FILE_OR_PUBLIC_KEY",
          :long => "--profitbricks-authorized-key FILE_OR_PUBLIC_KEY",
          :description => "SSH authorized keys for specified user",
          :proc => lambda { |o| Chef::Config[:knife][:profitbricks_authorized_key] = o }
        
        option :user,
          :short => "-u SSH-USER",
          :long => "--user SSH-USER",
          :description => "SSH user for provisioning",
          :proc => lambda { |o| Chef::Config[:knife][:ssh_user] = o }
      end
    end
    
    private
    def server_available_by_ssh?
      25.times.detect do 
        result = ssh_test
        sleep(5) unless result
        result
      end
    end

    def check_server_state!
      server.reload
#      log server.vm_state
      
      unless server.run?
        log "Server is not running. Try start!"
        server.start
        
        server.wait_for { ready? }
        server.wait_for { reload; run? }
      end

      if server.run? && server_available_by_ssh?
        log "Server is running."
        log ''
      else
        error "Can not start server!"
      end
    end
      
    def ssh(command)
      ssh = Chef::Knife::Ssh.new
      ssh.ui = ui
      ssh.name_args = [ server_ip, command ]
      ssh.config[:ssh_port] = 22
      #ssh.config[:ssh_gateway] = Chef::Config[:knife][:ssh_gateway] || config[:ssh_gateway]
      #ssh.config[:identity_file] = locate_config_value(:identity_file)
      ssh.config[:manual] = true
      ssh.config[:host_key_verify] = false
      ssh.config[:on_error] = :raise
      ssh
    end

    def ssh_root(command)
      s = ssh(command)
      s.config[:ssh_user] = "root"
#      s.config[:ssh_password] = root_password
      s
    end

    def ssh_user(command)
      s = ssh(command)
      s.config[:ssh_user] = Chef::Config[:knife][:ssh_user]
      s
    end

    def ssh_key
      ## SSH Key
      @ssh_key ||= begin
        file_path = Chef::Config[:knife][:profitbricks_authorized_key] || Dir.glob("#{ENV['HOME']}/.ssh/*.pub").first
        if File.exists?(file_path)
          File.open(file_path).read.gsub(/\n/,'')
        elsif file_path.nil?
          error("Could not read the provided public ssh key, check the authorized_key config.")
        else
          file_path
        end
      rescue Exception => e
        error(e.message)
      end
    end
    
    def upload_ssh_key
      ssh_user = Chef::Config[:knife][:ssh_user]
      dot_ssh_path = if ssh_user != 'root'
        ssh_root("useradd #{ssh_user} -G sudo -m -s /bin/bash").run
        "/home/#{ssh_user}/.ssh"
      else
        "/root/.ssh"
      end

      ssh_root("mkdir -p #{dot_ssh_path} && echo \"#{ssh_key}\" > #{dot_ssh_path}/authorized_keys && chmod -R go-rwx #{dot_ssh_path} && chown -R #{ssh_user} #{dot_ssh_path}").run
      
      log "Added the ssh key to the authorized_keys of #{ssh_user}"
      log ''
    end

    def custom_timeout(*args, &block)
      if defined?(Timeout) && Timeout.respond_to?(:timeout)
        Timeout.timeout(*args, &block)
      else
        timeout(*args, &block)
      end
    end

    def ssh_test
      begin
        custom_timeout 3 do
          s = TCPSocket.new server_ip, 22
          s.close
          true
        end
      rescue Timeout::Error, Errno::ECONNREFUSED, Net::SSH::Disconnect, Net::SSH::ConnectionTimeout
        false
      end
    end
    
    def change_password(options)
      user = options[:user]
      old_password = options[:old_password]
      password = options[:password]
      
      log "Change password for #{user}"
      log "old: #{old_password}"
      log "new: #{password}"
      log ''

      ssh_options = {:paranoid => false}

      if old_password
        login_user = user
#        ssh_options[:password] = old_password
#        command = 'passwd'
        command = <<-END
echo -e "#{password}\n#{password}\n" | passwd
END
      else
        login_user = 'root'
#        ssh_options[:password] = root_password
#        command = "passwd #{user}"
        command = <<-END
echo -e "#{password}\n#{password}\n" | passwd #{user}
END
      end

      begin
        Net::SSH.start( server_ip, login_user, ssh_options) do |ssh|
          ssh.exec! command.strip
          # not work at the moment
#          ssh.open_channel do |channel|
#             channel.on_request "exit-status" do |request_channel, data|
#                $exit_status = data.read_long
#             end
#             channel.on_data do |data_channel, data|
#                if data.inspect.include? "current"
#                  data_channel.send_data("#{old_password}\n");
#                elsif data.inspect.include? "New"
#                  data_channel.send_data("#{password}\n");
#                elsif data.inspect.include? "new"
#                  data_channel.send_data("#{password}\n");
#                else
#                  p '****************************'
#                  p data.inspect
#                  p '****************************'
#                end
#             end
#             channel.request_pty
#             channel.exec(command);
#             channel.wait
#
#             return $exit_status == 0
#          end
        end
      # network is not stable on new server
      rescue Exception => e
        @change_password_retry ||= 0
        @change_password_retry += 1
        
        sleep 2
        
        if @change_password_retry > 3
          raise e
        else
          retry
        end
      end
    end

    def change_password_root
      change_password :user => 'root', :old_password => root_password, :password => root_password(true)
    end

    def change_password_user
      change_password :user => Chef::Config[:knife][:ssh_user], 
        :old_password => nil, :password => user_password(true)
    end
  end
end
