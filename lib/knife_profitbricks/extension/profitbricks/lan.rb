module KnifeProfitbricks
  module Extension
    module Profitbricks
      module LAN
        def self.included(base)
          base.class_eval do
            property_reader :public
            alias public? public
          end
        end
      end
    end
  end
end

ProfitBricks::LAN.send :include, KnifeProfitbricks::Extension::Profitbricks::LAN
