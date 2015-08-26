module KnifeProfitbricks
  module CreateServer

    private
    def create_volumes
      unless server_config['volumes']
        error("No volumes specified! Please specify \"profitbricks\": {\"server\": \"volumes\": {\"root\": SIZE_IN_GB}} in your node!")
      end

      server_config['volumes'].collect do |hd_name, size_in_gb|
        name = "#{server_name}_#{hd_name}"
        log "Create Volume '#{name}' size: #{size_in_gb} GB"
        options = { :name => name }
        
        if hd_name == 'root'
          log "Based on #{boot_image.name}"
          options[:image] = boot_image.id 
          options[:imagePassword] = root_password if boot_image.public
        end

        options[:licenceType] = 'LINUX'
        options[:size] = size_in_gb

        volume = dc.create_volume(options)
        
        volume.wait_for { ready? }
        log "Volume '#{name}' created"
        log ''

        volume
      end
    end

    def do_create_server(boot_volume)
      ram_in_gb = server_config['ram_in_gb']
      ram = ram_in_gb * 1024
      cores = server_config['cores']
      
      log "Create server '#{server_name}': #{ram_in_gb} GB - #{cores} Cores - Boot volume: #{boot_volume.name}"
      
      server = dc.create_server(:cores => cores, :ram => ram, 
          :name => server_name, 
          :osType => 'LINUX',
          :bootVolume => boot_volume.id)
      
      server.wait_for { ready? }
      server.reload
      log "Server '#{server_name}' created"
      log ''

      server
    end

    def attach_volumes_to_server(volumes)
      volumes.each do |volume|
        log "Attach volume #{volume.name} to server #{server.name}"
        volume.attach(server.id)

        server.wait_for { ready? }
        volume.wait_for { ready? }
        log "Volume #{volume.name} attached at device_number #{volume.device_number}"
        log ''
      end
      
      server.reload
    end

    def create_server
      @server_is_new = true
      log "Create Server #{server_name.inspect}"
      log ''
      
      volumes = create_volumes
      @server = server = do_create_server volumes.first 
      attach_volumes_to_server volumes[1..-1]

      check_server_state!

      change_password_root
      upload_ssh_key
      change_password_user

      server
    end
  end
end
