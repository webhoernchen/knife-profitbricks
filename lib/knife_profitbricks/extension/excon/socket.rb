# Fix for
# ERROR: Excon::Error::Socket: getaddrinfo: Temporary failure in name resolution (SocketError)

module KnifeProfitbricks
  module Extension
    module Excon
      module Socket
        MAX_RETRIES = 20
        WAIT_AFTER_ERROR = 10 #seconds
        
        private
        def connect
          retry_count = 0

          begin
            super
          rescue ::Excon::Error::Socket, ::SocketError => e
            retry_count += 1
            if retry_count <= MAX_RETRIES
              print "#{e.class}: #{e.message}\nwait #{WAIT_AFTER_ERROR}s and retry #{retry_count} / #{MAX_RETRIES}\n"
              sleep WAIT_AFTER_ERROR
              retry
            else
              raise e
            end
          rescue Exception => e
            # Debug
            p e
            p e.class
            raise e
          end
        end
      end
    end
  end
end

Excon::Socket.prepend KnifeProfitbricks::Extension::Excon::Socket
