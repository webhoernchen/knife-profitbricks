module KnifeProfitbricks
  module Extension
    module Profitbricks
      module Volume
        LVS_ATTRIBUTES = KnifeProfitbricks::Base::LVS_ATTRIBUTES

        def self.included(base)
          base.class_eval do
            property_reader :licenceType, :name, :size, :deviceNumber, :href
#            property_reader LVS_ATTRIBUTES
          end
        end

        def lvs_support_complete?
          LVS_ATTRIBUTES.all? do |lvs_property| 
            read_property lvs_property
          end
        end

        def lvs_support
          LVS_ATTRIBUTES.inject({}) do |sum, lvs_property| 
            sum[convert_property_to_underscore(lvs_property)] = read_property lvs_property
            sum
          end
        end
      end
    end
  end
end

ProfitBricks::Volume.send :include, KnifeProfitbricks::Extension::Profitbricks::Volume
