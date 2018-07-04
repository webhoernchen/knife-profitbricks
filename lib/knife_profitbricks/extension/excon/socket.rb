# Fix for
# ERROR: Excon::Error::Socket: getaddrinfo: Temporary failure in name resolution (SocketError)

module KnifeProfitbricks
  module Extension
    module Excon
      module Socket
        
        private
        def connect
          retry_count = 0

          begin
            super
          rescue Excon::Error::Socket => e
            retry_count += 1
            if retry_count <= 5
              sleep 5
              retry
            else
              raise e
            end
          end
        end
      end
    end
  end
end

Excon::Socket.prepend KnifeProfitbricks::Extension::Excon::Socket
