require 'knife_profitbricks_fog/base'

module KnifeProfitbricksFog
  class ProfitbricksServerCook < Chef::Knife
    include KnifeProfitbricksFog::Base
      
    deps do
      require 'net/ssh'
      require 'net/ssh/multi'
      
      require 'chef/mixin/command'
      require 'chef/knife/solo_bootstrap'
      require 'chef/knife/solo_cook'
      
      require 'securerandom'
      require 'timeout'
      require 'socket'
    end

    banner "knife profitbricks server cook OPTIONS"


    def run
    end
  end
end
