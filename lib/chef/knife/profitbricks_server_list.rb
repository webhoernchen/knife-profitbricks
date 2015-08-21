require 'knife_profitbricks_fog/base'

module KnifeProfitbricks
  class ProfitbricksServerList < Chef::Knife
    include KnifeProfitbricks::Base

    banner "knife profitbricks server list OPTIONS"

    def run
      datacenters.each do |dc|
        log "DC: #{dc.name}"

        servers_for_datacenter(dc).each do |server|
          log " * Server: #{server.name} (#{server.cores} cores; #{server.ram} MB RAM; #{server.machine_state}, #{server.state})"

          log "   * OS: #{server.os_type}"
          log "   * IP: #{ips_for_server(server)}"
          
          volumes_info_for_server server
          lvs_info_for_server server
          
          log ""
        end
      end
    end

    private
    def datacenters
      @datacenters ||= compute.datacenters.all.sort_by(&:name)
    end
    alias dcs datacenters
    alias data_centers datacenters

    def servers
      @servers ||= compute.servers.all.sort_by(&:name)
    end

    def volumes
      @volumes ||= compute.volumes.all
    end

    def interfaces
      @interfaces ||= compute.interfaces.all
    end

    def servers_for_dc(dc)
      @servers_by_dc ||= servers.inject({}) do |sum, server|
        sum[server.data_center_id] ||= []
        sum[server.data_center_id] << server
        sum
      end

      @servers_by_dc[dc.id]
    end
    alias servers_for_datacenter servers_for_dc

    def volumes_for_server(server)
      @volumes_by_server ||= volumes.inject({}) do |sum, volume|
        sum[volume.server_ids] ||= []
        sum[volume.server_ids] << volume
        sum
      end

      avs__device_numbers = server.attached_volumes.inject({}) do |sum, v|
        sum[v['id']] = v['device_number']
        sum
      end

      @volumes_by_server[server.id].sort_by {|v| avs__device_numbers[v.id] }
    end

    def volumes_info_for_server(server)
      log "   * Volumes:"
      
      volumes_for_server(server).each do |volume|
        log "     * #{volume.name} (#{volume.size} GB)"
      end
    end

    def interfaces_for_server(server)
      @interfaces_by_server ||= interfaces.inject({}) do |sum, interface|
        sum[interface.server_id] ||= []
        sum[interface.server_id] << interface
        sum
      end

      @interfaces_by_server[server.id]
    end

    def ips_for_server(server)
      interfaces_for_server(server).collect(&:ips).flatten.collect(&:to_s).join(', ')
    end

    def lvs_info_for_server(server)
      if self.class::LVS_ATTRIBUTES.all? {|attr| server.send(attr) }
        log "   * LVS: true"
      else
        log "   * LVS:"
      
        self.class::LVS_ATTRIBUTES.each do |attr|
          log "     * #{attr}: #{server.send(attr)}"
        end
      end
    end
  end
end
