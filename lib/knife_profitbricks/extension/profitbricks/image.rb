module KnifeProfitbricks
  module Extension
    module Profitbricks
      module Image
        def self.included(base)
          base.class_eval do
            property_reader :name
          end
        end
      end
    end
  end
end

ProfitBricks::Image.send :include, KnifeProfitbricks::Extension::Profitbricks::Image
