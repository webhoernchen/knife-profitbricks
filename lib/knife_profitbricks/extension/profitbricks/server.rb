module KnifeProfitbricks
  module Extension
    module Profitbricks
      module Server
        def self.included(base)
          base.class_eval do
            property_reader :name, :cores, :ram, :vmState
           
            alias_method :list_volumes_without_order, :list_volumes
            alias_method :list_volumes, :list_volumes_with_order

            alias_method :reload_without_reset_cache, :reload
            alias_method :reload, :reload_with_reset_cache

            alias_method :volumes, :list_volumes
          end
        end

        def licence_type
          boot_volume.licence_type if boot_volume
        end

        def lvs_support_complete?
          boot_volume.lvs_support_complete? if boot_volume
        end

        def lvs_support
          boot_volume.lvs_support if boot_volume
        end

        def ips
          nics.collect(&:ips).flatten
        end

        def list_volumes_with_order
          @ordered_volumes ||= list_volumes_without_order.sort_by(&:device_number)
        end

        def boot_volume
          if @boot_volume.nil?
            @boot_volume = if boot_volume_attrs = read_property('bootVolume')
              get_volume boot_volume_attrs['id']
            else
              false
            end
          else
            @boot_volume
          end
        end

        def reload_with_reset_cache
          @boot_volume = nil
          @ordered_volumes = nil
          reload_without_reset_cache
        end

        def paused?
          vm_state == 'PAUSED'
        end

        def run?
          vm_state == 'RUNNING'
        end

        def shutoff?
          vm_state == 'SHUTOFF'
        end
      end
    end
  end
end

ProfitBricks::Server.send :include, KnifeProfitbricks::Extension::Profitbricks::Server
