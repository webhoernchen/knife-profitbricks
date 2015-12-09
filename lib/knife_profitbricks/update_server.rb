module KnifeProfitbricks
  module UpdateServer

    private
    def update_server
      @server_is_new = false
      log "Update Server #{server_name}"
      
      ram = server_config['ram_in_gb'] * 1024
      cores = server_config['cores']

      log "Check LVS state #{server_name}"
      if server.lvs_support_complete?
        log "LVS is available"
      else
        log "Update LVS settings"
       
        boot_volume = server.boot_volume
        boot_volume.update self.class::LVS_CONFIG
        boot_volume.wait_for { ready? }
        boot_volume.reload

        log "LVS config updated"
      end
      
      if server.ram != ram || server.cores != cores
        server.update :cores => cores, :ram => ram
        server.wait_for { ready? }
      end
     
      update_nics
      update_volumes
    end

    def update_nics
      log "Update nic"

      if reserve_ip? && !server.ips.any? {|ip| ProfitBricks::IPBlock.ips.include?(ip) }
        lans = dc.lans
        lan_ids = lans.collect(&:id)

        nic = server.nics.detect {|n| lan_ids.include? n.lan_id }

        options = {:firewallActive => nic.firewallActive, 
          :lan => nic.lan_id}
        add_options_for_reserved_ip options
        new_nic = server.create_nic options
        new_nic.wait_for { ready? }

        nic.fw_rules.each do |rule|
          new_rule = new_nic.create_firewall_rule rule.clone_options
          new_rule.wait_for { ready? }
        end
        new_nic.wait_for { ready? }

        nic.delete
        nic.wait_for { ready? }
      end
      log "Nic updated"
    end

    def update_volumes
      threads = server_config['volumes'].collect do |hd_name, size_in_gb|
        _thread_for_update_volume hd_name, size_in_gb
      end

      threads.each(&:join)
      server.reload
    end

    def _thread_for_update_volume(hd_name, size_in_gb)
      Thread.new do
        _update_volume hd_name, size_in_gb
      end
    end

    def _update_volume(hd_name, size_in_gb)
      name = "#{server_name}_#{hd_name}"
      log_message =  "Update Volume '#{name}' size: #{size_in_gb} GB"
      
      volume = server.volumes.find do |v|
        v.name == name
      end
     
      if volume.size > size_in_gb
        error "The size of the Volume can only be increased and not decreased! Volume: #{name} - old size #{volume.size} GB - new size #{size_in_gb} GB" 
      elsif volume.size != size_in_gb
        volume.update :size => size_in_gb
        volume.wait_for { ready? }
      end

      log log_message
      volume
    rescue => e
      log log_message
      raise e
    end

    def find_and_update_server
      error("No server name specified! Please specify \"profitbricks\": {\"server\": \"name\"} in your node!") unless server_name
      log "Locate Server #{server_name}"
      
      server = dc.server_by_name(server_name)
      
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
