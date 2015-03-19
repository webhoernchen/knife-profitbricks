module KnifeProfitbricksFog
  module Base

    def self.included(base)
      base.class_eval do 
        deps do 
          require 'fog/profitbricks'
          require 'chef/knife'
          
          Chef::Knife.load_deps
          
          Chef::Config[:solo] = true
        end

        option :profitbricks_data_bag,
          :short => "-account NAME",
          :long => "--profitbricks-data-bag NAME",
          :description => "Data bag for profitbricks account",
          :proc => lambda { |o| Chef::Config[:knife][:profitbricks_data_bag] = o }
      end
    end

    private
    def compute
      if @compute
        @compute
      else
        user, password = detect_user_and_password
        log "Establish connection to ProfitBricks for #{user.inspect}"
        @compute = Fog::Compute.new({:provider => 'ProfitBricks', 
          :profitbricks_username => user, :profitbricks_password => password})
        log "Established ..."
        log "\n"
        @compute
      end
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
