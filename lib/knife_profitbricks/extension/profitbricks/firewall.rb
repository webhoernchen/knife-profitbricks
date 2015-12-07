module KnifeProfitbricks
  module Extension
    module Profitbricks
      module Firewall
        ATTRIBUTES_FOR_COPY = [:name, :protocol, :sourceMac, :sourceIp, :targetIp,
              :portRangeStart, :portRangeEnd, :icmpType, :icmpCode]

        def self.included(base)
          base.class_eval do
            property_reader ATTRIBUTES_FOR_COPY
          end
        end

        def clone_options
          ATTRIBUTES_FOR_COPY.inject({}) do |sum, attr|
            sum[attr] = self.send attr
            sum
          end
        end
      end
    end
  end
end

ProfitBricks::Firewall.send :include, KnifeProfitbricks::Extension::Profitbricks::Firewall
