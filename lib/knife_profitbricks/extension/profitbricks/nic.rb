module KnifeProfitbricks
  module Extension
    module Profitbricks
      module NIC
        def self.included(base)
          base.class_eval do
            property_reader :ips, :firewallActive
            
            alias firewall_rules fwrules
            alias firewall_active? firewall_active
          end
        end

        def lan_id
          read_property :lan
        end
      end
    end
  end
end

ProfitBricks::NIC.send :include, KnifeProfitbricks::Extension::Profitbricks::NIC
