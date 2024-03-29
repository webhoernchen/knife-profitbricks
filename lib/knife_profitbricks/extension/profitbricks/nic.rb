module KnifeProfitbricks
  module Extension
    module Profitbricks
      module NIC
        def self.included(base)
          base.class_eval do
            property_reader :ips, :ipv6Ips, :firewallActive, :mac, :name
            
            alias firewall_rules fwrules
            alias firewall_active? firewall_active
            alias ipv4_ips ips
            alias ipv6_ips ipv6Ips
          end
        end

        def lan_id
          read_property :lan
        end

        def last_4_traffic_periods
          @last_4_traffic_periods ||= ProfitBricks::Billing::TrafficRow.by_last_4_periods_and_nic_id(id).flatten.inject({}) do |sum, row|
            sum[row.period] ||= []
            sum[row.period] << row
            sum
          end
        end
      end
    end
  end
end

ProfitBricks::NIC.send :include, KnifeProfitbricks::Extension::Profitbricks::NIC
