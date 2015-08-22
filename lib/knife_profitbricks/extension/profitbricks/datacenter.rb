module KnifeProfitbricks
  module Extension
    module Profitbricks
      module Datacenter
        def self.included(base)
          base.class_eval do
            property_reader :name

            def self.list_sorted
              list.sort_by(&:name)
            end
          end
        end
      end
    end
  end
end

ProfitBricks::Datacenter.send :include, KnifeProfitbricks::Extension::Profitbricks::Datacenter
