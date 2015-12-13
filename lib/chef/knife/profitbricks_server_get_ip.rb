require 'knife_profitbricks/base'
require 'knife_profitbricks/config'

module KnifeProfitbricks
  class ProfitbricksServerGetIp < Chef::Knife
    include KnifeProfitbricks::Base
    include ProfitBricksProvision::Server::Base
    include KnifeProfitbricks::Config
    
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
      ProfitBricksProvision::Config.config = _profitbricks_config
      
      ProfitBricksProvision::ServerGetIp.run
    end
  end
end
