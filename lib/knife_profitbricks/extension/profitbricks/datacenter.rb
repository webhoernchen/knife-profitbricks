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

        def current_traffic_rows
          @current_traffic_rows ||= ProfitBricks::Billing::TrafficRow.by_current_period_and_dc_id id
        end

        def current_traffic_period
          row = current_traffic_rows.first
          row && row.period
        end

        def previous_traffic_rows
          @previous_traffic_rows ||= ProfitBricks::Billing::TrafficRow.by_previous_period_and_dc_id id
        end

        def previous_traffic_period
          row = previous_traffic_rows.first
          row && row.period
        end
      end
    end
  end
end

ProfitBricks::Datacenter.send :include, KnifeProfitbricks::Extension::Profitbricks::Datacenter
ProfitBricks::Datacenter.send :include, KnifeProfitbricks::Extension::Profitbricks::HasLocation
