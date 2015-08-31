module KnifeProfitbricks
  module Extension
    module Profitbricks
      module Request

        def self.included(base)
        end

        def ready?
          status.metadata['status'] == 'DONE'
        end

        def set_request_id_to_targets
          s = status
          s.metadata['targets'].each do |target_item|
            target = target_item['target']
            model_type = target['type']
            model_id = target['id']

            ObjectSpace.each_object(ProfitBricks::Model) do |model|
              if model.id == model_id && model.model_type == model_type
                model.requestId = id
              end
            end
          end
        end
      end
    end
  end
end

ProfitBricks::Request.send :include, KnifeProfitbricks::Extension::Profitbricks::Request
