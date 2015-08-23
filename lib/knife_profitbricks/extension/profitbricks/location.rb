module KnifeProfitbricks
  module Extension
    module Profitbricks
      module Location
        def self.included(base)
          base.class_eval do
            property_reader :name
          end
        end
      end
    end
  end
end

ProfitBricks::Location.send :include, KnifeProfitbricks::Extension::Profitbricks::Location
