require 'knife_profitbricks_fog/base'

module KnifeProfitbricksFog
  class ProfitbricksServerList < Chef::Knife
    include KnifeProfitbricksFog::Base

    banner "knife profitbricks server list OPTIONS"

    def run
      compute.datacenters.each do |dc|
        log "DC: #{dc.name}"

        compute.servers.all.select {|s| s.data_center_id == dc.id }.each do |server|
          log " * Server: #{server.name} (#{server.cores} cores; #{server.ram} MB RAM; IP: #{server.interfaces.first.ips}; #{server.machine_state})"

          compute.volumes.all.select {|s| s.server_ids == server.id }.each do |volume|
            log "   * Volume: #{volume.name} (#{volume.size} GB)"
          end
          
          log ""
        end
      end
    end

    private
    def data_centers
      @data_centers ||= compute.datacenters.all
    end
    alias dcs data_centers
  end
end
