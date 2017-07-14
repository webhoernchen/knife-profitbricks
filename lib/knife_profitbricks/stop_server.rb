module KnifeProfitbricks
  module StopServer

    private
    def shutdown_server
      if server.running?
        log "Server is running."
        log 'Shutdown server'

        if ssh_test
          custom_timeout 10 do
            ssh('sudo shutdown -h now').run
          end
          
          server.wait_for { reload; shutoff? }
          
          log ''
          log 'Server is down'
        elsif Chef::Config[:knife][:force_shutdown]
          log ''
          log_error 'Server is not available by ssh'
        else
          log ''
          error 'Server is not available by ssh'
        end
      else
        server.wait_for { reload; shutoff? }
        log 'Server is down'
      end
    rescue
      log ''

      if Chef::Config[:knife][:force_shutdown]
        log_error 'Shutdown is not working'
      else
        error 'Shutdown is not working'
      end
    end

    def stop_server
      if server.available?
        log "Server hardware is running."
        log 'Stop server'
        
        server.stop
        server.wait_for { ready? }
        server.wait_for { reload; inactive? }
        
        log ''
        log 'Server is inactive'
      else
        server.wait_for { ready? }
        server.wait_for { reload; inactive? }
        log 'Server is inactive'
      end
    end
  end
end
