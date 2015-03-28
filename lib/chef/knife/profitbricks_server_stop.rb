require 'knife_profitbricks_fog/base'
require 'knife_profitbricks_fog/config'
require 'knife_profitbricks_fog/data_center'
require 'knife_profitbricks_fog/ssh_commands'

module KnifeProfitbricksFog
  class ProfitbricksServerStop < Chef::Knife
    include KnifeProfitbricksFog::Base
    include KnifeProfitbricksFog::Config
    include KnifeProfitbricksFog::DataCenter
    include KnifeProfitbricksFog::SshCommands
    
    deps do
      require 'net/ssh'
      require 'net/ssh/multi'
      
      require 'chef/mixin/command'
      require 'chef/json_compat'
      
      require 'timeout'
      require 'socket'
    end
    
    banner "knife profitbricks server stop OPTIONS"

    option :chef_node_name,
      :short => "-N NAME",
      :long => "--node-name NAME",
      :description => "The Chef node name for your new server node",
      :proc => Proc.new { |o| Chef::Config[:knife][:chef_node_name] = o }


    def run
      if server
        shutdown_server
        log ''
        stop_server
      else
        error "Server '#{server_name}' not found in data_center '#{dc_name}'"
      end
    end

    private
    def server
      @server ||= find_server
    end

    def find_server
      compute
      dc = compute.datacenters.all.find { |d| d.name == dc_name }

      unless dc
        error "Datacenter #{dc_name.inspect} not exist"
      end

      compute.servers.all.detect do |s|
        s.data_center_id == dc.id && s.name == server_name
      end
    end

    def shutdown_server
      if server.machine_state == 'RUNNING'
        log "Server is running."
        log 'Shutdown server'

        ssh('sudo shutdown -h now').run

        server.wait_for { machine_state == 'SHUTOFF' }
        
        log ''
        log 'Server is down'
        
        server.reload
      else
        server.wait_for { machine_state == 'SHUTOFF' }
        server.reload
        log 'Server is down'
      end
    end

    def stop_server
      if server.state == 'AVAILABLE'
        log "Server hardware is running."
        log 'Stop server'
        
        server.stop
        server.wait_for { state == 'INACTIVE' }
        
        log ''
        log 'Server is inactive'
        
        server.reload
      else
        log 'Server is inactive'
      end
    end
  end
end
