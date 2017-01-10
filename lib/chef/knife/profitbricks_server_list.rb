require 'knife_profitbricks/base'

module KnifeProfitbricks
  class ProfitbricksServerList < Chef::Knife
    include KnifeProfitbricks::Base

    banner "knife profitbricks server list OPTIONS"
    
    option :no_traffic,
      :long => "--no-traffic",
      :description => "No traffic data will be displayed",
      :proc => lambda {|o| Chef::Config[:knife][:display_traffic] = false },
      :default => false

    def run
      ProfitBricks::Datacenter.list_sorted.each do |dc|
        log "DC: #{dc.name}"
        log " * Location: #{dc.location_label}"
      
        if display_traffic?
          list_traffic_for dc
          log ""
        end

        dc.servers.each do |server|
          log " * Server: #{server.name} (#{server.cores} cores - #{server.cpu_family}; #{server.ram} MB RAM)"
          log "   * Allocation state: #{server.allocation_state}"
          log "   * State: #{server.vm_state}"
          log "   * OS: #{server.licence_type}"
          
          ips_for_server server, dc
          volumes_info_for_server server
          lvs_info_for_server server if server.boot_volume
          
          log ""
        end
      end
     
      unless ProfitBricks::IPBlock.all.empty?
        log ''
        log 'IP blocks:'
        ProfitBricks::IPBlock.all.each_with_index do |ip_block, i|
          log "Index: #{i}"
          log " * Name: #{ip_block.name}"
          log " * Location: #{ip_block.location_label}"
          log " * IPs:"

          ip_block.ips.each do |ip|
            info = reserved_hash[ip] || 'unused'
            log "  * #{ip} => #{info}"
          end

          log ''
        end
      end
      
      if display_traffic?
        log ''
        log 'Traffic summary:'
        list_traffic_for ProfitBricks
      end
    end

    private
    def display_traffic?
      o = Chef::Config[:knife][:display_traffic]
      o.nil? || o
    end

    def volumes_info_for_server(server)
      log "   * Volumes:"
      
      server.volumes.each do |volume|
        log "     * #{volume.name} - #{volume.disc_type} (#{volume.size} GB)"
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

    def ips_for_server(server, dc)
      server.nics.each_with_index do |nic, index|
        log "   * Nic #{nic.name || index.next}:"
        log "     * Mac: #{nic.mac}"

        ips = nic.ips.collect do |ip|
          reserved_info = reserved_info_for_ip ip
          reserved_hash[ip] = "DC: #{dc.name} => Server: #{server.name}"
          "#{ip}#{reserved_info}"
        end.join(', ')
        log "     * IPs: #{ips}"
        
        if display_traffic?
          list_traffic_for nic, '     '
        end
      end
    end

    def reserved_info_for_ip(ip)
      fixed = ProfitBricks::IPBlock.ips.include? ip
      fixed ? ' (reserved)' : ''
    end

    def reserved_hash
      @reserved_hash ||= {}
    end

    def list_traffic_for(dc_or_nic, space=' ')
      dc_or_nic.last_3_traffic_periods.each do |period, traffic_rows|
        traffic =  traffic_rows.inject({}) do |sum, traffic_row|
          sum[traffic_row.in_or_out] ||= 0
          sum[traffic_row.in_or_out] += traffic_row.megabytes
          sum
        end.collect do |in_or_out, sum_in_megabytes|
          "#{in_or_out}: #{sum_in_megabytes} MB"
        end.join(', ')
        
        log "#{space}* Traffic period: #{period} (#{traffic})"
      end
    end
  end
end
