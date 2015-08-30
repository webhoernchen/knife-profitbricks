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

        def request_with_set_request_id_to_model(*args)
          caller_binding = binding.eval('self') # get object which called this method
          response = request_without_set_request_id_to_model(*args)
          
          if caller_binding.respond_to? :requestId
            caller_binding.requestId = (response[:requestId] || response['requestId'])
          end

          response
        end
      end
    end
  end
end

ProfitBricks.send :extend, KnifeProfitbricks::Extension::Profitbricks::ClassMethods
