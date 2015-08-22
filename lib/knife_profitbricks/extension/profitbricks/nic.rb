module KnifeProfitbricks
  module Extension
    module Profitbricks
      module NIC
        def self.included(base)
          base.class_eval do
            property_reader :ips
          end
        end
      end
    end
  end
end

ProfitBricks::NIC.send :include, KnifeProfitbricks::Extension::Profitbricks::NIC
