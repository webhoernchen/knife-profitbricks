module KnifeProfitbricks
  module Extension
    module Profitbricks
      module Location
        def self.included(base)
          base.class_eval do
            property_reader :name

            def self.by_id(id)
              hashed_by_id[id]
            end

            private
            def self.hashed_by_id
              @hashed_by_id ||= list.inject({}) do |sum, location|
                sum[location.id] = location
                sum
              end
            end
          end
        end

        def label
          [id, name].collect(&:to_s).join(' => ')
        end
      end
    end
  end
end

ProfitBricks::Location.send :include, KnifeProfitbricks::Extension::Profitbricks::Location
