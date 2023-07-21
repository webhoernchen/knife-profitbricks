require 'knife_profitbricks/base'
require 'knife_profitbricks/config'
require 'knife_profitbricks/data_center'

module KnifeProfitbricks
  class ProfitbricksServerGetIp < Chef::Knife
    include KnifeProfitbricks::Base
    include KnifeProfitbricks::Config
    include KnifeProfitbricks::DataCenter
    
    deps do
      require 'chef/json_compat'
    end
    
    banner "knife profitbricks server get ip OPTIONS"

    option :chef_node_name,
      :short => "-N NAME",
      :long => "--node-name NAME",
      :description => "The Chef node name for your new server node",
      :proc => Proc.new { |o| Chef::Config[:knife][:chef_node_name] = o }
    
    option :v4,
      :short => "-4",
      :long => "--v4",
      :description => "Get IPv4 address",
      :proc => Proc.new { |o| self.ipv4_only = true }
    
    option :v6,
      :short => "-6",
      :long => "--v6",
      :description => "Get IPv6 address",
      :proc => Proc.new { |o| self.ipv6_only = true }
    
    option :all,
      :long => "--all",
      :description => "Get all ip addresses (ipv4 and ipv6) - separate by comma",
      :proc => Proc.new { |o| self.all_ips = true }

    def self.ipv4_only=(value)
      @ipv4_only = value
    end

    def self.ipv4_only?
      @ipv4_only
    end

    def self.ipv6_only=(value)
      @ipv6_only = value
    end

    def self.ipv6_only?
      @ipv6_only
    end

    def self.all_ips=(value)
      @all_ips = value
    end

    def self.all_ips?
      @all_ips
    end

    def run
      unless dc
        error "Datacenter #{dc_name.inspect} not exist"
      end

      if server
        print server_ip_for_output
      else
        error "Server '#{server_name}' not found in data_center '#{dc_name}'"
      end
    end

    private
    def dc
      @dc ||= ProfitBricks::Datacenter.find_by_name dc_name
    end

    def server
      @server ||= dc.server_by_name server_name
    end

    def server_ip_for_output
      klass = self.class

      if klass.all_ips?
        server.ips.join(',')
      else
        if klass.ipv4_only?
          server.ipv4_ips
        elsif klass.ipv6_only?
          server.ipv6_ips
        else
          server.ipv4_ips
        end.first
      end
    end
  end
end
