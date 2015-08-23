require 'knife_profitbricks/base'
require 'knife_profitbricks/config'
require 'knife_profitbricks/data_center'
require 'knife_profitbricks/ssh_commands'

module KnifeProfitbricks
  class ProfitbricksServerStop < Chef::Knife
    include KnifeProfitbricks::Base
    include KnifeProfitbricks::Config
    include KnifeProfitbricks::DataCenter
    include KnifeProfitbricks::SshCommands
    
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
      dc = ProfitBricks::Datacenter.find_by_name(dc_name)

      unless dc
        error "Datacenter #{dc_name.inspect} not exist"
      end

      dc.server_by_name(server_name)
    end

    def shutdown_server
      if server.running?
        log "Server is running."
        log 'Shutdown server'

        ssh('sudo shutdown -h now').run

        server.wait_for { ready? }
        server.wait_for { paused? }
        
        log ''
        log 'Server is down'
        
        server.reload
      else
        server.wait_for { paused? }
        server.reload
        log 'Server is down'
      end
    end

    def stop_server
      if server.pausd?
        log "Server hardware is running."
        log 'Stop server'
        
        server.stop
        server.wait_for { shutoff? }
        
        log ''
        log 'Server is inactive'
        
        server.reload
      else
        log 'Server is inactive'
      end
    end
  end
end
