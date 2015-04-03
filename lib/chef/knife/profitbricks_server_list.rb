require 'knife_profitbricks_fog/base'

module KnifeProfitbricksFog
  class ProfitbricksServerList < Chef::Knife
    include KnifeProfitbricksFog::Base

    banner "knife profitbricks server list OPTIONS"

    def run
      datacenters.each do |dc|
        log "DC: #{dc.name}"

        servers_for_datacenter(dc).each do |server|
          log " * Server: #{server.name} (#{server.cores} cores; #{server.ram} MB RAM; IP: #{server.interfaces.first.ips}; #{server.machine_state}, #{server.state})"


          volumes_for_server(server).each do |volume|
            log "   * Volume: #{volume.name} (#{volume.size} GB)"
          end
          
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
      @volumes_by_dc ||= volumes.inject({}) do |sum, volume|
        sum[volume.server_ids] ||= []
        sum[volume.server_ids] << volume
        sum
      end

      avs__device_numbers = server.attached_volumes.inject({}) do |sum, v|
        sum[v['id']] = v['device_number']
        sum
      end

      @volumes_by_dc[server.id].sort_by {|v| avs__device_numbers[v.id] }
    end
  end
end
