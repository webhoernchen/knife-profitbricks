module KnifeProfitbricksFog
  module Config
    LVS_CONFIG = {
      :cpuHotPlug => true, 
      :ramHotPlug => true, 
      :nicHotPlug => true, 
      :nicHotUnPlug => true, 
      :discVirtioHotPlug => true, 
      :discVirtioHotUnPlug => true
    }

    private
    def _profitbricks_config
      n = Chef::Config[:knife][:chef_node_name]
      n = "nodes/#{n}.json"
      n = JSON.parse(File.read n)
      config = n['profitbricks']
      log "No profitbricks config found! Please specify \"profitbricks\" in your node!" unless config
      config
    rescue Errno::ENOENT
      error "Node #{n.inspect} not exist"
    end

    def profitbricks_config
      @profitbricks_config ||= _profitbricks_config
    end

    def server_config
      @server_config ||= profitbricks_config['server']
    end

    def server_name
      server_config['name']
    end

    def server_ip
      server && server.interfaces.first.ips
    end

    def boot_image_name
      @image_name ||= Chef::Config[:knife][:profitbricks_image]
    end

    def boot_image
      @image ||= compute.images.all.find do |i|
        i.region == dc_region &&
          (boot_image_name.is_a?(Regexp) && i.name.match(boot_image_name) ||
          i.name == boot_image_name)
      end
    end
      
    def root_password(reset=false)
      @root_password = nil if reset
      @root_password ||= SecureRandom.hex
    end

    def user_password(reset=false)
      @user_password = nil if reset
      @user_password ||= SecureRandom.hex
    end
  end
end
