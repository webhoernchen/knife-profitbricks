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
          require 'knife_profitbricks/extension/net/ssh'
          require 'knife_profitbricks/extension/profitbricks/profitbricks'
          require 'knife_profitbricks/extension/profitbricks/model'
          require 'knife_profitbricks/extension/profitbricks/has_location'
          require 'knife_profitbricks/extension/profitbricks/server'
          require 'knife_profitbricks/extension/profitbricks/datacenter'
          require 'knife_profitbricks/extension/profitbricks/volume'
          require 'knife_profitbricks/extension/profitbricks/nic'
          require 'knife_profitbricks/extension/profitbricks/location'
          require 'knife_profitbricks/extension/profitbricks/image'
          require 'knife_profitbricks/extension/profitbricks/lan'
          require 'knife_profitbricks/extension/profitbricks/request'
          require 'knife_profitbricks/extension/profitbricks/ipblock'
          require 'knife_profitbricks/extension/profitbricks/firewall'
          require 'knife_profitbricks/extension/profitbricks/location'
          require 'knife_profitbricks/extension/profitbricks/wait_for'
          require 'knife_profitbricks/extension/profitbricks/billing'
          require 'knife_profitbricks/extension/profitbricks/billing/traffic'
          require 'knife_profitbricks/extension/excon/socket'
          require 'ostruct'
          
          Chef::Knife.load_deps
          
          Chef::Config[:solo] = true
          Chef::Config[:solo_legacy_mode] = true
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
      log "Establish connection to ProfitBricks for #{auth_config.user.inspect}"

      set_config_username_and_password
      set_config_api_token
      set_config_defaults

      log "Established ..."
      log "\n"
    end

    def set_config_username_and_password
      return unless auth_config.user && auth_config.password

      ProfitBricks::Config.password = auth_config.password
      ProfitBricks::Config.username = auth_config.user
    end

    def set_config_api_token
      return unless auth_config.token

      expire = Time.new auth_config.token_expire
      now = Time.now + 3600 * 12 # 12 hours

      error "Token must be valid for 12 hours (#{auth_config.token_name} - #{auth_config.token_expire})" if expire <= now

      ProfitBricks::Config.headers = {
        'Authorization' => "Bearer #{auth_config.token}"
      }
    end

    def set_config_defaults
      ProfitBricks.configure do |config|
        config.global_classes = false
        config.timeout = 300

        # upgrade to v6
        path_prefix = config.path_prefix.gsub(/(cloudapi\/v)[3-5]$/, '\16')
        config.path_prefix = path_prefix if path_prefix != config.path_prefix
      end
    end

    def load_data_bag(*args)
      secret_path = Chef::Config[:encrypted_data_bag_secret]
      secret_key = Chef::EncryptedDataBagItem.load_secret secret_path
      content = Chef::DataBagItem.load(*args).raw_data
      Chef::EncryptedDataBagItem.new(content, secret_key).to_hash
    end

    def auth_config
      @auth_config ||= if data_bag_name = Chef::Config[:knife][:profitbricks_data_bag]
        data_bag = load_data_bag 'profitbricks', data_bag_name

        OpenStruct.new user: data_bag['user'],
          password: data_bag['password'],
          token: data_bag['token'],
          token_expire: data_bag['token_expire'],
          token_name: data_bag['token_name']
      else
        OpenStruct.new user: ENV['PROFITBRICKS_USER'],
          password: ENV['PROFITBRICKS_PASSWORD'],
          token: ENV['PROFITBRICKS_TOKEN'],
          token_expire: ENV['PROFITBRICKS_TOKEN_EXPIRE'],
          token_name: ENV['PROFITBRICKS_TOKEN_NAME']
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
