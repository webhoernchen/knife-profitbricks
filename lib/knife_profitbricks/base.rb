module KnifeProfitbricks
  module Base

    LVS_ATTRIBUTES = [
      :cpuHotPlug,
      :ramHotPlug,
      :nicHotPlug,
      :nicHotUnplug,
      :discVirtioHotPlug,
      :discVirtioHotUnplug
    ]

    def self.included(base)
      base.class_eval do 
        deps do 
          require 'profitbricks'
          require 'chef/knife'
          require 'knife_profitbricks/extension/profitbricks/model'
          require 'knife_profitbricks/extension/profitbricks/server'
          require 'knife_profitbricks/extension/profitbricks/datacenter'
          require 'knife_profitbricks/extension/profitbricks/volume'
          require 'knife_profitbricks/extension/profitbricks/nic'
          require 'knife_profitbricks/extension/profitbricks/location'
          require 'knife_profitbricks/extension/profitbricks/image'
          require 'knife_profitbricks/extension/profitbricks/lan'
          
          Chef::Knife.load_deps
          
          Chef::Config[:solo] = true
        end

        option :profitbricks_data_bag,
          :short => "-a NAME",
          :long => "--profitbricks-data-bag NAME",
          :description => "Data bag for profitbricks account",
          :proc => lambda { |o| Chef::Config[:knife][:profitbricks_data_bag] = o }

        def self.method_added(name)
          if name.to_s == 'run' && !@run_added
            @run_added = true
            alias run_without_establish_connection run
            alias run run_with_establish_connection
          end
        end
      end
    end

    def run_with_establish_connection
      establish_connection
      run_without_establish_connection
    end

    private
    def establish_connection
      user, password = detect_user_and_password
      log "Establish connection to ProfitBricks for #{user.inspect}"
      
      ProfitBricks.configure do |config|
        config.username = user
        config.password = password
        config.global_classes = false
        config.timeout = 120
      end
      
      log "Established ..."
      log "\n"
    end

    def load_data_bag(*args)
      secret_path = Chef::Config[:encrypted_data_bag_secret]
      secret_key = Chef::EncryptedDataBagItem.load_secret secret_path
      content = Chef::DataBagItem.load(*args).raw_data
      Chef::EncryptedDataBagItem.new(content, secret_key).to_hash
    end

    def detect_user_and_password
      if data_bag_name = Chef::Config[:knife][:profitbricks_data_bag]
        data_bag = load_data_bag 'profitbricks', data_bag_name

        [data_bag['user'], data_bag['password']]
      else
        [ENV['PROFITBRICKS_USER'], ENV['PROFITBRICKS_PASSWORD']]
      end
    end

    def log(m)
      ui.info m
    end

    def log_error(m)
      error m, :abort => false
    end

    def error(m, options={})
      ui.error m
      exit 1 if !options.has_key?(:abort) || options[:abort]
    end
  end
end
