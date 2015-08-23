require 'knife_profitbricks/base'
require 'knife_profitbricks/config'
require 'knife_profitbricks/data_center'

module KnifeProfitbricks
  class ProfitbricksServerGetIp < Chef::Knife
    include KnifeProfitbricks::Base
    include KnifeProfitbricks::Config
    include KnifeProfitbricks::DataCenter
    
    deps do
      require 'chef/json_compat'
    end
    
    banner "knife profitbricks server get ip OPTIONS"

    option :chef_node_name,
      :short => "-N NAME",
      :long => "--node-name NAME",
      :description => "The Chef node name for your new server node",
      :proc => Proc.new { |o| Chef::Config[:knife][:chef_node_name] = o }


    def run
      dc = ProfitBricks::DataCenter.find_by_name(dc_name)

      unless dc
        error "Datacenter #{dc_name.inspect} not exist"
      end

      server = dc.server_by_name(server_name)
 

      if server
        print server.ips.first
      else
        error "Server '#{server_name}' not found in data_center '#{dc_name}'"
      end
    end
  end
end
