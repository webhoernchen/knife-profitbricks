require 'knife_profitbricks/base'

module KnifeProfitbricks
  class ProfitbricksServerList < Chef::Knife
    include KnifeProfitbricks::Base
    include ProfitBricksProvision::Server::Base

    banner "knife profitbricks server list OPTIONS"

    def run
      ProfitBricksProvision::ServerList.run
    end
  end
end
