module KnifeProfitbricks
  module Config
    def self.included(base)
      base.class_eval do 
      end
    end

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
  end
end
