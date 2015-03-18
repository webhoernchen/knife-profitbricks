require 'knife_profitbricks_fog/base'
require 'knife_profitbricks_fog/config'
require 'knife_profitbricks_fog/create_server'
require 'knife_profitbricks_fog/update_server'

module KnifeProfitbricksFog
  class ProfitbricksServerCook < Chef::Knife
    include KnifeProfitbricksFog::Base
    include KnifeProfitbricksFog::Config
    include KnifeProfitbricksFog::CreateServer
    include KnifeProfitbricksFog::UpdateServer
      
    deps do
      require 'net/ssh'
      require 'net/ssh/multi'
      
      require 'chef/mixin/command'
      require 'chef/knife'
      require 'chef/knife/solo_bootstrap'
      require 'chef/knife/solo_cook'
      require 'chef/json_compat'
      
      require 'securerandom'
      require 'timeout'
      require 'socket'
    end

    banner "knife profitbricks server cook OPTIONS"

    option :run_list,
      :short => "-r RUN_LIST",
      :long => "--run-list RUN_LIST",
      :description => "Comma separated list of roles/recipes to apply",
      :proc => lambda { |o| Chef::Config[:knife][:run_list] = o.split(/[\s,]+/) },
      :default => []

    option :profitbricks_image,
      :short => "-image NAME",
      :long => "--profitbricks-image NAME",
      :description => "Profitbricks image name",
      :proc => lambda { |o| Chef::Config[:knife][:profitbricks_image] = o }

    option :node_name,
      :short => "-N NAME",
      :long => "--node-name NAME",
      :description => "The Chef node name for your new server node",
      :proc => Proc.new { |o| Chef::Config[:knife][:node_name] = o }

    def run
      compute
      dc


    end

    private
      
    def server
      @server ||= (find_and_update_server || create_server)
    end
  end
end
