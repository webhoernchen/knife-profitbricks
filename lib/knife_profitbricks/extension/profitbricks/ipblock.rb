module KnifeProfitbricks
  module Extension
    module Profitbricks
      module IPBlock
        def self.included(base)
          base.class_eval do
            property_reader :ips
          end
        end
      end
    end
  end
end

ProfitBricks::IPBlock.send :include, KnifeProfitbricks::Extension::Profitbricks::IPBlock
