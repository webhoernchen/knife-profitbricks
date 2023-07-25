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
        
        option :no_retry_for_server,
          :long => "--no-retry",
          :description => "No retry to start server after failure",
          :proc => lambda { |o| Chef::Config[:knife][:profitbricks_no_retry] = true }
      end
    end
    
    private
    def server_available_by_ssh?
      max_retries = 10
      max_retries.times.detect do |n|
        result = ssh_test :time => n.next, :retries => max_retries
        sleep 5 unless result
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

      if server.run? && server_available_by_ssh? && loginable_by_ssh?
        log "Server is running."
        log ''
      else
        error "Can not start server!"
      end
    rescue Exception => e
      p e.message
      p e.backtrace
      @check_server_state_retries ||= 0
      @check_server_state_retries += 1

      if @check_server_state_retries > 1 || Chef::Config[:knife][:profitbricks_no_retry]
        raise e
      else
        config = Chef::Config[:knife]
        old_value = config[:force_shutdown]
        config[:force_shutdown] = true

        log ''
        shutdown_server
        log ''
        stop_server
        log ''
        
        config[:force_shutdown] = old_value
        reset_server_ips
  
        unless reserve_ip?
          log 'Recreate nics ...'
          nics = server.nics
          lan_ids = nics.collect(&:lan_id)
          nics.each do |n|
            n.delete
            n.wait_for { ready? }
          end
          
          server.reload
          server.wait_for { ready? }

          lan_ids.each do |lan_id|
            options = {:firewallActive => false, :lan => lan_id}
            nic = server.create_nic options 
            nic.wait_for { ready? }
          end
          nsize = server.nics.size
          error "Recreate nics failed!" if nsize != 1

          server.reload
          server.wait_for { ready? }
          log 'Recreate nics finised!'
          log ''
        end

        sleep 10

        log "Retry (#{@check_server_state_retries}) ..."
        retry
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
      log "Add the ssh key to the authorized_keys of #{ssh_user}"
      dot_ssh_path = if ssh_user != 'root'
        ssh_root("[[ -z $(cat /etc/passwd | awk -F: '{print $1}' | grep -E '^#{ssh_user}$') ]] && useradd #{ssh_user} -G sudo -m -s /bin/bash || echo '#{ssh_user} already exist!'").run
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

    def ssh_test(options={})
      begin
        custom_timeout 5 do
          s = TCPSocket.new server_ip, 22
          s.close
          true
        end
      rescue Timeout::Error, Errno::ECONNREFUSED, Net::SSH::Disconnect, Net::SSH::ConnectionTimeout, IOError => e
        info = options.empty? ? nil : "#{options[:time]} / #{options[:retries]}"
        log '  * ' + [e.class, server_ip, Time.now.to_s, info].compact.collect(&:to_s).join(' - ')
        false
      end
    end

    def loginable_by_ssh?
      max_retries = 5
      max_retries.times.collect do |n|
        result = _loginable_by_ssh? :time => n.next, :retries => max_retries
        sleep 5 unless result
        result
      end[-3..-1].all?
    end

    def _loginable_by_ssh?(options={})
      begin
        custom_timeout 10 do
          command = 'date > /dev/null'
          if @server_is_new
            ssh_root command
          else
            ssh_user command
          end.run
        end

        true
      rescue Exception => e
        info = options.empty? ? nil : "#{options[:time]} / #{options[:retries]}"
        log '  * ' + [e.class, server_ip, Time.now.to_s, info].compact.collect(&:to_s).join(' - ')
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

      ssh_options = {:verify_host_key => :never}

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
