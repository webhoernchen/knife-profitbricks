module KnifeProfitbricks
  module DataCenter

    private
    def dc_name
      @dc_name ||= (profitbricks_config['dc'] || profitbricks_config['data_center'])
      @dc_name = [@dc_name, Time.now.to_i.to_s].join('_') if @dc_name == 'Example'
      @dc_name
    end
    alias data_center_name dc_name

    def dc_region
      @dc_region ||= profitbricks_config['region']
    end

    def _dc
      error("No datacenter specified! Please specify \"profitbricks\": {\"dc\": \"name\"} in your node!") unless dc_name

      log "Locating Datacenter #{dc_name.inspect}"
      
      dc = ProfitBricks::Datacenter.find_by_name dc_name
     
      if dc
        log "Datacenter #{dc_name.inspect} exist"
      else
        log "Datacenter #{dc_name.inspect} not exist"
        log "Create Datacenter #{dc_name.inspect}"
        
        error("No region specified! Please specify \"profitbricks\": {\"region\": \"name\"} in your node!") unless dc_region
        
        dc = ProfitBricks::Datacenter.create(:name => dc_name, location: dc_region)
        dc.wait_for { ready? }
        
        log "Datacenter #{dc_name.inspect} created"
      end
      log ''
      
      dc.wait_for { ready? }
      dc
    end

    def dc
      @dc ||= _dc
    end
  end
end
