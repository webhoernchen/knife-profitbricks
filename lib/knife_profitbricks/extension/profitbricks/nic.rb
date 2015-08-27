module KnifeProfitbricks
  module Extension
    module Profitbricks
      module NIC
        def self.included(base)
          base.class_eval do
            property_reader :ips, :firewallActive, :firewallrules
            
            alias firewall_rules firewallrules
            alias firewall_active? firewall_active
          end
        end
      end
    end
  end
end

ProfitBricks::NIC.send :include, KnifeProfitbricks::Extension::Profitbricks::NIC
