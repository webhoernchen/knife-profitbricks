module KnifeProfitbricks
  module CreateServer

    private
    def do_create_server
      ram_in_gb = server_config['ram_in_gb']
      ram = ram_in_gb * 1024
      cores = server_config['cores']
      
      cpu = server_config['cpu']
      cpu ||= self.class::CPU_DEFAULT_KEY
      cpu = cpu.to_sym
      
      if self.class::CPU_FAMILIES.has_key? cpu
        cpu = self.class::CPU_FAMILIES[cpu]
      else
        raise "cpu must be #{self.class::CPU_FAMILIES.keys.join ' or '}!"
      end
      
      log "Create server '#{server_name}': #{ram_in_gb} GB - #{cores} Cores (#{cpu})"
      
      volumes = build_params_for_volumes
      server = dc.create_server :cores => cores, :ram => ram, :name => server_name,
        :cpuFamily => cpu, :volumes => volumes

      server.wait_for { ready? }
      
      add_nic_to_server server

      server.reload

      log "Server '#{server_name}' created"
      log ''

      server
    end

    def public_lan
      @public_lan  ||= _public_lan
    end

    def _public_lan
      log 'Find or create public lan'
      public_lan = dc.lans.detect(&:public?) || dc.create_lan(:public => true, :ipv6CidrBlock => 'AUTO')
      public_lan.wait_for { ready? }
      log 'Public lan is ready'
      
      log ''
      
      public_lan
    end

    def add_nic_to_server(server)
      log 'Add nic to server'
      
      options = {:firewallActive => false, :lan => public_lan.id}
      add_options_for_reserved_ip options
      nic = server.create_nic options 
      nic.wait_for { ready? }
      
      log 'Nic for server added!'
      log ''
      
      nic
    end

    def add_options_for_reserved_ip(options)
      if reserve_ip?
        log 'Reserve 1 IP'
        ipblock = ProfitBricks::IPBlock.reserve :location => dc_region, 
          :size => 1, :name => server_name
        
        log "1 IP reserved: #{ipblock.ips.first}"
        options[:ips] = ipblock.ips
      end
    end

    def build_params_for_volumes
      unless configured_volumes = server_config['volumes']
        error("No volumes specified! Please specify \"profitbricks\": {\"server\": \"volumes\": {\"root\": SIZE_IN_GB}} in your node!")
      end

      configured_volumes.map do |hd_name, size_in_gb|
        if size_in_gb.is_a? Hash
          build_params_for_volume hd_name, size_in_gb['size'], size_in_gb['type']
        else
          build_params_for_volume hd_name, size_in_gb
        end
      end
    end

    def build_params_for_volume(hd_name, size_in_gb, type='HDD')
      name = "#{server_name}_#{hd_name}"
      log_message = "Volume '#{hd_name}' (#{type}) size: #{size_in_gb} GB"
      options = { :name => name, :size => size_in_gb, :type => type }
      
      if hd_name == 'root'
        log_message = "#{log_message} - Based on #{boot_image.name}"
        options[:image] = boot_image.id
        options[:bootOrder] = 'PRIMARY'
        
        if boot_image.public
          options[:imagePassword] = root_password
          options[:sshKeys] = [ssh_key]
        end
      else
        options[:licenceType] = 'OTHER'
        options[:bootOrder] = 'NONE'
      end

      log "  * #{log_message}\n"

      options
    rescue => e
      log "#{log_message}: Error\n\n"
      raise e
    end

    def create_server
      @server_is_new = true
      log "Create Server #{server_name.inspect}"
      log ''
      
      @server = server = do_create_server
      
      check_server_state!

      change_password_root
      upload_ssh_key
      change_password_user

      server
    end
  end
end
