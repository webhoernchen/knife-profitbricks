require 'knife_profitbricks_fog/base'
require 'knife_profitbricks_fog/config'
require 'knife_profitbricks_fog/data_center'

module KnifeProfitbricksFog
  class ProfitbricksServerGetIp < Chef::Knife
    include KnifeProfitbricksFog::Base
    include KnifeProfitbricksFog::Config
    include KnifeProfitbricksFog::DataCenter
    
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
      compute
      dc = compute.datacenters.all.find { |d| d.name == dc_name }

      unless dc
        error "Datacenter #{dc_name.inspect} not exist"
      end

      server = compute.servers.all.detect do |s|
        s.data_center_id == dc.id && s.name == server_name
      end

      if server
        ip = server && server.interfaces.first.ips
        print ip
      else
        error "Server '#{server_name}' not found in data_center '#{dc_name}'"
      end
    end
  end
end
