module KnifeProfitbricks
  module Extension
    module Profitbricks
      module Datacenter
        def self.included(base)
          base.class_eval do
            property_reader :name

            def self.list_sorted
              list.sort_by(&:name)
            end

            def self.find_by_name(name)
              list.find { |d| d.name == name }
            end
          end
        end

        def server_by_name(server_name)
          servers.detect do |server|
            server.name == server_name
          end
        end

        def last_3_traffic_periods
          @last_3_traffic_periods ||= ProfitBricks::Billing::TrafficRow.by_last_4_periods_and_dc_id(id).flatten.inject({}) do |sum, row|
            sum[row.period] ||= []
            sum[row.period] << row
            sum
          end
        end
      end
    end
  end
end

ProfitBricks::Datacenter.send :include, KnifeProfitbricks::Extension::Profitbricks::Datacenter
ProfitBricks::Datacenter.send :include, KnifeProfitbricks::Extension::Profitbricks::HasLocation
