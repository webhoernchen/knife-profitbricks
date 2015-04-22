module KnifeProfitbricksFog
  module UpdateServer

    private
    def update_server
      @server_is_new = false
      log "Update Server #{server_name}"
      
      ram = server_config['ram_in_gb'] * 1024
      cores = server_config['cores']

      log "Check LVS state #{server_name}"
      if self.class::LVS_ATTRIBUTES.all? {|attr| server.send(attr).to_s == 'true' }
        log "LVS is available"
      else
        log "Update LVS settings"
        
        server.options = self.class::LVS_CONFIG
        server.update
        server.wait_for { ready? }

        log "LVS config updated"
      end
      
      if server.ram != ram || server.cores != cores
        server.options = { :cores => cores, :ram => ram }
        server.update
        server.wait_for { ready? }
      end
      
      update_volumes
    end

    def update_volumes
      server_config['volumes'].each do |hd_name, size_in_gb|
        name = "#{server_name}_#{hd_name}"
        log "Update Volume '#{name}' size: #{size_in_gb} GB"
        volume = compute.volumes.all.find do |v|
          v.data_center_id == dc.id && v.name == name
        end
       
        if volume.size > size_in_gb
          error "The size of the Volume can only be increased and not decreased! Volume: #{name} - old size #{volume.size} GB - new size #{size_in_gb} GB" 
        elsif volume.size != size_in_gb
          volume.options = { :size => size_in_gb }
          volume.update
          volume.wait_for { ready? }
          volume.reload
        end
      end

      server.reload
    end

    def find_and_update_server
      error("No server name specified! Please specify \"profitbricks\": {\"server\": \"name\"} in your node!") unless server_name
      log "Locate Server #{server_name}"
      
      server = compute.servers.all.find do |s| 
        s.data_center_id == dc.id &&
          s.name == server_name
      end
      
      if server
        log "Server #{server_name} found"
        @server = server
        update_server
      else
        log "Server #{server_name} not exist"
      end

      server
    end
  end
end
