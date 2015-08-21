require 'knife_profitbricks/base'

module KnifeProfitbricks
  class ProfitbricksServerList < Chef::Knife
    include KnifeProfitbricks::Base

    banner "knife profitbricks server list OPTIONS"

    def run
      ProfitBricks::Datacenter.list.sort_by do |dc|
        dc.properties['name']
      end.each do |dc|
        log "DC: #{dc.properties['name']}"

        dc.servers.each do |server|
          name = server.properties['name']
          cores = server.properties['cores']
          ram = server.properties['ram']
          vm_state = server.properties['vmState']

          log " * Server: #{name} (#{cores} cores; #{ram} MB RAM; #{vm_state})"
          
          if boot_volume_attrs = server.properties['bootVolume']
            boot_volume = server.get_volume(boot_volume_attrs['id'])
            licence_type = boot_volume.properties['licenceType']
            log "   * OS: #{licence_type}"
          end

          log "   * IP: #{ips_for_server(server)}"
          
          volumes_info_for_server server
          lvs_info_for_server boot_volume if boot_volume_attrs
          
          log ""
        end
      end
    end

    private
    def volumes_info_for_server(server)
      log "   * Volumes:"
      
      server.list_volumes.each do |volume|
        name = volume.properties['name']
        size = volume.properties['size']

        log "     * #{name} (#{size} GB)"
      end
    end

    def ips_for_server(server)
      server.nics.collect do |nic|
        nic.properties['ips']
      end.flatten.join(', ')
    end

    def lvs_info_for_server(boot_volume)
      if self.class::LVS_ATTRIBUTES.all? {|attr| boot_volume.properties[attr.to_s] }
        log "   * LVS: true"
      else
        log "   * LVS:"
      
        self.class::LVS_ATTRIBUTES.each do |attr|
          log "     * #{attr}: #{boot_volume.properties[attr.to_s]}"
        end
      end
    end
  end
end
