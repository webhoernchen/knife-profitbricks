module KnifeProfitbricksFog
  module CreateServer

    private
    def create_volumes
      unless server_config['volumes']
        error("No volumes specified! Please specify \"profitbricks\": {\"server\": \"volumes\": {\"root\": SIZE_IN_GB}} in your node!")
      end

      server_config['volumes'].collect do |hd_name, size_in_gb|
        name = "#{server_name}_#{hd_name}"
        log "Create Volume '#{name}' size: #{size_in_gb} GB"
        options = { :storageName => name }
        
        if hd_name == 'root'
          log "Based on #{boot_image.name}"
          options[:mountImageId] = boot_image.id 
          options[:profitBricksImagePassword] = root_password if boot_image.public
        end

        volume = compute.volumes.create(:data_center_id => dc.id, :size => size_in_gb, :options => options)
        
        volume.wait_for { ready? }
        volume.reload
        log "Volume '#{name}' created"
        log ''

        volume
      end
    end

    def do_create_server(boot_volume)
      ram = server_config['ram_in_gb'] * 1024
      cores = server_config['cores']
      
      log "Create server '#{server_name}': #{ram} GB - #{cores} Cores - Boot volume: #{boot_volume.name}"
      
      server = compute.servers.create(:data_center_id => dc.id, :cores => cores, :ram => ram, 
        :options => {
          :serverName => server_name, 
          :internetAccess => true, 
          :osType => 'LINUX',
          :bootFromStorageId => boot_volume.id,
          :cpuHotPlug => true, 
          :ramHotPlug => true, 
          :nicHotPlug => true, 
          :nicHotUnPlug => true, 
          :discVirtioHotPlug => true, 
          :discVirtioHotUnPlug => true})
      
      server.wait_for { ready? }
      server.reload
      log "Server '#{server_name}' created"
      server
    end

    def attach_volumes_to_server(volumes)
      current_device_number = server.attached_volumes.collect {|v| v['device_number'] }.max

      volumes.each_with_index do |volume, index|
        log "Attach volume #{volume.name} to server #{server.name} at device number #{current_device_number + index.next}"
        volume.attach(server.id, :device_number => current_device_number + index.next)

        server.wait_for { ready? }
        volume.wait_for { ready? }
        server.reload
        volume.reload
        log "Volume #{volume.name} attached"
      end
    end

    def create_server
      @server_is_new = true
      log "Create Server #{server_name.inspect}"
      
      volumes = create_volumes
      @server = server = do_create_server volumes.first 
      attach_volumes_to_server volumes[1..-1]

      check_server_state!

      change_password_root
      upload_ssh_key
      change_password_user

      server
    end

    def server_available_by_ssh?
      5.times.detect { ssh_test } 
    end

    def check_server_state!
      server.reload
      log server.machine_state
      
      unless server.machine_state == 'RUNNING'
        log "Server is not running. Try start!"
        server.start
        server.wait_for { ready? }
      end

      if server.machine_state == 'RUNNING' && server_available_by_ssh?
        log "Server is running."
      else
        error "Can not start server!"
      end
    end
  end
end
