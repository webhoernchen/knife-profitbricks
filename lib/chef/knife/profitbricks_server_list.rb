require 'knife_profitbricks/base'

module KnifeProfitbricks
  class ProfitbricksServerList < Chef::Knife
    include KnifeProfitbricks::Base

    banner "knife profitbricks server list OPTIONS"

    def run
      ProfitBricks::Datacenter.list_sorted[-1..-1].each do |dc|
        log "DC: #{dc.name}"
        log " * Location: #{dc.location_label}"
        
        rows = ProfitBricks::Billing::TrafficRow.by_current_period_and_dc_id dc.id
        rows.each do |row|
          log " * Traffic #{row.in_or_out}: #{row.megabytes}"
        end

        log ""

        dc.servers.each do |server|
          log " * Server: #{server.name} (#{server.cores} cores; #{server.ram} MB RAM)"
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
    end

    private
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
      ips = server.ips
      
      if ips.count == 1
        ip = ips.first
        reserved_info = reserved_info_for_ip ip
        reserved_hash[ip] = "DC: #{dc.name} => Server: #{server.name}"
        
        log "   * IP: #{ip}#{reserved_info}"
      else
        log "   * IPs:"
        ips.each do |ip|
          reserved_info = reserved_info_for_ip ip
        reserved_hash[ip] = "DC: #{dc.name} => Server: #{server.name}"
          
          log "     * #{ip}#{reserved_info}"
        end
      end
    end

    def reserved_info_for_ip(ip)
      fixed = ProfitBricks::IPBlock.ips.include?(ip)
      fixed ? ' (reserved)' : ''
    end

    def reserved_hash
      @reserved_hash ||= {}
    end
  end
end
