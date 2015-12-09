module KnifeProfitbricks
  module Extension
    module Profitbricks
      module HasLocation
        def self.included(base)
          base.class_eval do
#            property_reader :location
          end
        end

        def location_id
          read_property :location
        end

        def location
          @location ||= ProfitBricks::Location.by_id location_id
        end

        def location_label
          location.label
        end
      end
    end
  end
end
