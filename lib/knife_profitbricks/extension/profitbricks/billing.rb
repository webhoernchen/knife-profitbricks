module ProfitBricks::Billing
  def self.client
    @client ||= connect
  end

  def self.request(params)
    response = client.request params
    parse_json response.body
  end

  def self.companies
    response = request(:method => :get,
      :path => '/profile',
      :expects => 200
    )
    response['companies']
  end

  def self.contract_ids
    @contract_ids ||= companies.collect {|c| c['contractId'] }
  end

  def self.contract_id
    contract_ids.first
  end

  def self.products
    request(:method => :get,
      :path => "/#{contract_id}/usage",
      :expects => 200
    )
  end

  private
  def self.connect
    url = 'https://billingapi.profitbricks.com'

    params = {
      :user => ProfitBricks::Config.username,
      :password => ProfitBricks::Config.password,
      :debug => ProfitBricks::Config.debug,
      :omit_default_port => true,
      :query => { :depth => 1 }
    }

    Excon.new(url, params)
  end
  
  def self.parse_json(body)
    JSON.parse(body) unless body.nil? || body.empty?
  rescue JSON::ParserError => error
    raise error
  end
end
