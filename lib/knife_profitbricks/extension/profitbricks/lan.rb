module KnifeProfitbricks
  module Extension
    module Profitbricks
      module LAN
        def self.included(base)
          base.class_eval do
            property_reader :public, :ipv6CidrBlock

            alias public? public
            alias ipv6_cidr_block ipv6CidrBlock
          end
        end
      end
    end
  end
end

ProfitBricks::LAN.send :include, KnifeProfitbricks::Extension::Profitbricks::LAN
