module KnifeProfitbricks
  module CreateServer

    private
    def create_volumes
      unless configured_volumes = server_config['volumes']
        error("No volumes specified! Please specify \"profitbricks\": {\"server\": \"volumes\": {\"root\": SIZE_IN_GB}} in your node!")
      end

      threads = configured_volumes.collect do |hd_name, size_in_gb|
        _thread_for_create_volume hd_name, size_in_gb
      end

      threads.each(&:join)
      threads.collect(&:value)
    end

    def _thread_for_create_volume(hd_name, size_in_gb)
      Thread.new do
        _create_volume hd_name, size_in_gb
      end
    end

    def _create_volume(hd_name, size_in_gb)
      name = "#{server_name}_#{hd_name}"
      log_message = "Create Volume '#{name}' size: #{size_in_gb} GB"
      options = { :name => name, :size => size_in_gb, :type => 'HDD' } # type SSD
      
      if hd_name == 'root'
        log_message = "#{log_message}\nBased on #{boot_image.name}"
        options[:image] = boot_image.id
        
        if boot_image.public
          options[:imagePassword] = root_password
          options[:sshKeys] = [ssh_key]
        end
      else
        options[:licenceType] = 'OTHER' 
      end

      volume = dc.create_volume(options)
      
      volume.wait_for { ready? }
      log "#{log_message}\nVolume '#{name}' created\n\n"

      volume
    rescue => e
      log "#{log_message}: Error\n\n"
      raise e
    end

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
      
      server = dc.create_server :cores => cores, :ram => ram, :name => server_name,
        :cpuFamily => cpu
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
      log 'Create public lan'
      
      public_lan = dc.lans.detect(&:public?) || dc.create_lan(:public => true)
      public_lan.wait_for { ready? }
      
      log 'Public lan created!'
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

    def attach_volumes_to_server(volumes)
      volumes.each do |volume|
        log "Attach volume #{volume.name} to server #{server.name}"
        volume.attach(server.id)

        volume.wait_for { ready? }
        volume.wait_for { volume.reload; !device_number.nil? }
        
        log "Volume #{volume.name} attached at device_number #{volume.device_number}"
        log ''
      end
      
      server.reload
    end

    def set_boot_volume_to_server(boot_volume)
      log "Set boot volume: #{boot_volume.name}"

      server.update :bootVolume => {:id => boot_volume.id, 
        :type => 'volume', :href => boot_volume.href}

      server.wait_for { ready? }
      server.reload
      boot_volume.reload
      
      log "Volume #{boot_volume.name} is used as boot volume!"
      log ''
    end

    def create_server
      @server_is_new = true
      log "Create Server #{server_name.inspect}"
      log ''
      
      volumes = create_volumes
      boot_volume = volumes.detect {|v| v.name.end_with? 'root' }
      @server = server = do_create_server
      attach_volumes_to_server volumes
      set_boot_volume_to_server boot_volume
      
      check_server_state!

      change_password_root
      upload_ssh_key
      change_password_user

      server
    end
  end
end
