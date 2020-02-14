module KnifeProfitbricks
  module Extension
    module Profitbricks
      module ClassMethods

        def self.extended(base)
          class << base
            alias request_without_set_request_id_to_model request
            alias request request_with_set_request_id_to_model
          end
        end

        def request_with_set_request_id_to_model(options)
          retry_count = 0
          max_retry_count = 50

          response = begin
            request_without_set_request_id_to_model options
          rescue JSON::ParserError => e
            if e.message.match?(/Rate\s*Limit\s*Exceeded/i) && retry_count <= max_retry_count
              divider = "*" * 20 + "\n"
              print divider
              print e.message
              print divider
              print "Wait ... #{retry_count}/#{max_retry_count}\n"
              print divider
              retry_count += 1
              sleep 20
              retry
            else
              raise e
            end
          end

          request_id = (response[:requestId] || response['requestId'])
         
          if options[:method].to_sym != :get && request_id
            ProfitBricks::Request.get(request_id).set_request_id_to_targets
          end

          response
        end

        def last_3_traffic_periods
          @last_3_traffic_periods ||= ProfitBricks::Billing::TrafficRow.by_last_4_periods.flatten.inject({}) do |sum, row|
            sum[row.period] ||= []
            sum[row.period] << row
            sum
          end
        end
      end
    end
  end
end

ProfitBricks.send :extend, KnifeProfitbricks::Extension::Profitbricks::ClassMethods
