require 'knife_profitbricks/base'

module KnifeProfitbricks
  class ProfitbricksServerList < Chef::Knife
    include KnifeProfitbricks::Base

    banner "knife profitbricks server list OPTIONS"

    def run
      ProfitBricks::Datacenter.list_sorted.each do |dc|
        log "DC: #{dc.name}"

        dc.servers.each do |server|
          log " * Server: #{server.name} (#{server.cores} cores; #{server.ram} MB RAM)"
          log "   * Allocation state: #{server.allocation_state}"
          log "   * State: #{server.vm_state}"
          log "   * OS: #{server.licence_type}"
          log "   * IP: #{server.ips.join(',')}"
          
          volumes_info_for_server server
          lvs_info_for_server server if server.boot_volume
          
          log ""
        end
      end
    end

    private
    def volumes_info_for_server(server)
      log "   * Volumes:"
      
      server.volumes.each do |volume|
        log "     * #{volume.name} (#{volume.size} GB)"
      end
    end

    def lvs_info_for_server(server)
      if server.lvs_support_complete?
        log "   * LVS: complete"
      else
        log "   * LVS:"
      
        server.lvs_support.each do |k, v|
          log "     * #{k}: #{v}"
        end
      end
    end
  end
end
