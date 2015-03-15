module KnifeProfitbricksFog
  class ProfitbricksServerList < Chef::Knife

    deps do 
      require 'fog/profitbricks'
      require 'chef/knife'
      
      Chef::Knife.load_deps
    end

    banner "knife profitbricks server list OPTIONS"

    option :profitbricks_data_bag,
      :short => "-account NAME",
      :long => "--profitbricks-data-bag NAME",
      :description => "Data bag for profitbricks account",
      :proc => lambda { |o| Chef::Config[:knife][:profitbricks_data_bag] = o }


    def run
      Chef::Config[:solo] = true
      
      compute.datacenters.each do |dc|
        log "Name: #{dc.name}"

        compute.servers.all.select {|s| s.data_center_id == dc.id }.each do |server|
          log " * Name: #{server.name}"

          compute.volumes.all.select {|s| s.data_center_id == dc.id }.each do |volume|
            log "   * Name: #{volume.name}"
          end
        end
      end
    end

    private
    def data_centers
      @data_centers ||= compute.datacenters.all
    end
    alias dcs data_centers

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

    def log(m)
      ui.info m
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
  end
end
