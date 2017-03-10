module KnifeProfitbricks
  module Extension
    module Net
      module SSH
        def configuration_for(host, use_ssh_config=nil)
          if use_ssh_config.nil?
            use_ssh_config = true
          end

          super host, use_ssh_config
        end
      end
    end
  end
end

require 'net/ssh'
class << Net::SSH
  prepend KnifeProfitbricks::Extension::Net::SSH
end
