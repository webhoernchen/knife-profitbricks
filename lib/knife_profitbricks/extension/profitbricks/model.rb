module KnifeProfitbricks
  module Extension
    module Profitbricks
      module Model
        module ClassMethods

          def self.extended(base)
            base.send :include, InstanceMethods

            base.class_eval do 
              alias ready_without_request_id_not_exit? ready?
              alias ready? ready_with_request_id_not_exit?
            end
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
          def ready_with_request_id_not_exit?
            if requestId
              ready_without_request_id_not_exit?
            else
              true
            end
          end

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
