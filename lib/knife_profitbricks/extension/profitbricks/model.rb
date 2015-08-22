module KnifeProfitbricks
  module Extension
    module Profitbricks
      module Model
        module ClassMethods

          def self.extended(base)
            base.send :include, InstanceMethods
          end

          private
          def property_reader(*names)
            names.flatten.each do |name|
              name = name.to_s

              define_method name do
                read_property name
              end

              u_name = convert_property_to_underscore(name)
              define_method u_name do
                read_property name
              end if name != u_name
            end
          end

          def convert_property_to_underscore(property_name)
            property_name.to_s.gsub(/(.+)([A-Z])/, '\1_\2').downcase
          end
        end

        module InstanceMethods
          private
          def read_property(name)
            if properties.keys.collect(&:to_s).include?(name.to_s)
              properties[name.to_s]
            else
              raise "Property '#{name}' not exist!"
            end
          end

          def convert_property_to_underscore(*args)
            self.class.send(:convert_property_to_underscore, *args)
          end
        end
      end
    end
  end
end

ProfitBricks::Model.send :extend, KnifeProfitbricks::Extension::Profitbricks::Model::ClassMethods
