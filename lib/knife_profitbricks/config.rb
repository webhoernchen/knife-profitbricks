module KnifeProfitbricks
  module Config
    LVS_CONFIG = {
      :cpuHotPlug => true, 
      :ramHotPlug => true, 
      :nicHotPlug => true, 
      :nicHotUnPlug => true, 
      :discVirtioHotPlug => true, 
      :discVirtioHotUnPlug => true
    }

    CPU_FAMILIES = {
      :amd => 'AMD_OPTERON',
      :intel => 'INTEL_XEON'
    }

    CPU_DEFAULT_KEY = :amd

    private
    def _node_config
      n = Chef::Config[:knife][:chef_node_name]
      n = "nodes/#{n}.json"
      JSON.parse File.read n
    end

    def node_config
      @node_config || _node_config
    end

    def _profitbricks_config
      config = node_config['profitbricks']
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
      @server_ip ||= (server && server.ips.first)
    end

    def reset_server_ip
      @server_ip = nil
    end

    def reserve_ip?
      if server_config.has_key? 'fixed_ip'
        Chef::Config[:deprecated_error] = "\n option 'fixed_ip' removed soon!\nPlease use 'reserve_ip'!"
      else
        server_config['reserve_ip'] ||= false
      end
    end

    def boot_image_name
      @image_name ||= if image = server_config['image']
        if m = image.match(/^\/(.*)\/$/)
          Regexp.new m[1]
        else
          image
        end
      else
        Chef::Config[:knife][:profitbricks_image]
      end
    end

    def boot_image
      @image ||= detect_boot_image
    end

    def detect_boot_image
      ProfitBricks::Image.list.select do |i|
        i.location == dc_region &&
          (boot_image_name.is_a?(Regexp) && i.name.match(boot_image_name) ||
          i.name == boot_image_name)
      end.sort_by(&:name).last || raise("No boot image found for #{boot_image_name.inspect}")
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
