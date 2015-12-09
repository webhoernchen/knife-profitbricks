module KnifeProfitbricks
  module StopServer

    private
    def shutdown_server
      if server.running?
        log "Server is running."
        log 'Shutdown server'

        ssh('sudo shutdown -h now').run
        
        server.wait_for { reload; shutoff? }
        
        log ''
        log 'Server is down'
      else
        server.wait_for { reload; shutoff? }
        log 'Server is down'
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
