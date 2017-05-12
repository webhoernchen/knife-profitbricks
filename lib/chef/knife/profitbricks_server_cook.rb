require 'knife_profitbricks/base'
require 'knife_profitbricks/config'
require 'knife_profitbricks/data_center'
require 'knife_profitbricks/ssh_commands'
require 'knife_profitbricks/create_server'
require 'knife_profitbricks/update_server'
require 'knife_profitbricks/stop_server'
require 'knife_profitbricks/provision'

module KnifeProfitbricks
  class ProfitbricksServerCook < Chef::Knife
    include KnifeProfitbricks::Base
    include KnifeProfitbricks::Config
    include KnifeProfitbricks::DataCenter
    include KnifeProfitbricks::SshCommands
    include KnifeProfitbricks::CreateServer
    include KnifeProfitbricks::UpdateServer
    include KnifeProfitbricks::StopServer
    include KnifeProfitbricks::Provision
      
    deps do
      require 'net/ssh'
      require 'net/ssh/multi'
      
#      require 'chef/mixin/command'
      require 'chef/knife'
      require 'chef/knife/solo_bootstrap'
      require 'chef/knife/solo_cook'
      require 'chef/json_compat'
      
      require 'securerandom'
      require 'timeout'
      require 'socket'
    end

    banner "knife profitbricks server cook OPTIONS"

    option :run_list,
      :short => "-r RUN_LIST",
      :long => "--run-list RUN_LIST",
      :description => "Comma separated list of roles/recipes to apply",
      :proc => lambda { |o| Chef::Config[:deprecated_error] = "\n-r or --run-list is deprecated and will be removed soon!\nPlease use -o or --override-runlist"; Chef::Config[:knife][:override_runlist] = o },
      :default => []
    
    option :override_runlist,
      :short       => '-o RunlistItem,RunlistItem...,',
      :long        => '--override-runlist',
      :description => 'Replace current run list with specified items (Comma separated list of roles/recipes)',
      :proc => lambda { |o| Chef::Config[:knife][:override_runlist] = o },
      :default => []

    option :profitbricks_image,
      :short => "-image NAME",
      :long => "--profitbricks-image NAME",
      :description => "Profitbricks image name",
      :proc => lambda { |o| Chef::Config[:knife][:profitbricks_image] = o }

    option :chef_node_name,
      :short => "-N NAME",
      :long => "--node-name NAME",
      :description => "The Chef node name for your new server node",
      :proc => Proc.new { |o| Chef::Config[:knife][:chef_node_name] = o }

    option :forward_agent,
      :short => '-A',
      :long        => '--forward-agent',
      :description => 'Forward SSH authentication. Adds -E to sudo, override with --sudo-command.',
      :boolean     => true,
      :default     => false,
      :proc => Proc.new { |o| Chef::Config[:knife][:forward_agent] = o }

    def run
      error Chef::Config[:deprecated_error] if Chef::Config[:deprecated_error]

      dc

      server
      check_server_state!
      add_server_to_known_hosts__if_new
      bootstrap_or_cook

      reboot_server__if_new
    end

    private
      
    def server
      @server ||= (find_and_update_server || create_server)
    end
  end
end
