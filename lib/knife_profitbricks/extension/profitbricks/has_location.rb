module KnifeProfitbricks
  module Extension
    module Profitbricks
      module HasLocation
        def self.included(base)
          base.class_eval do
            property_reader :location
          end
        end

        def _location
          @location ||= ProfitBricks::Location.by_id(location)
        end

        def location_label
          _location.label
        end
      end
    end
  end
end
