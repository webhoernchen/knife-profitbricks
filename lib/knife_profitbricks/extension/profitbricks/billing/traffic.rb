require 'active_support/core_ext/date'
require 'active_support/core_ext/date_time'
require 'active_support/core_ext/time'
require 'active_support/core_ext/numeric/bytes'
require 'active_support/core_ext/string/conversions'

class ProfitBricks::Billing::Traffic
  attr_accessor :in_or_out, :dc_id, :dc_name, :days

  def self.by_current_period
    by_period default_period
  end

  def self.by_period_for_date(date)
    by_period period_for date
  end

  def self.by_current_period_and_dc_id(dc_id)
    meta_line = by_current_period.first
    by_current_period[1..-1].collect do |line|
      initialize meta_line, line
    end.select do |traffic|
      traffic.dc_id == dc_id
    end.inject({}) do |sum, traffic|
      sum[traffic.in_or_out] = traffic
      sum
    end
  end

  def initialize(meta_line, line)
    meta_line.each_with_index do |attr_name, index|
      case attr_name
      when /^IN\/OUT$/i
        self.in_or_out = line[index]
      when /^VDC\ UUID$/
        self.dc_id = line[index]
      when /^VDC\ NAME$/
        self.dc_name = line[index]
      when /^[0-9]{4}(-[0-9]{2}){2}$/
        self.days ||= {}
        day = attr_name.split('-').last.to_i
        self.days[day] = line[index]
      end
    end
  end

  private
  def self.by_period(period)
    @periods ||= {}
    @periods[period] ||= ProfitBricks::Billing.request(:method => :get,
      :path => "/#{contract_id}/traffic/#{period}",
      :expects => 200)['traffic']
  end

  def self.default_period
    period_for Date.today
  end

  def self.period_for(date)
    date.strftime '%Y-%m'
  end

  def self.request(params)
    ProfitBricks::Billing.request params
  end
  
  def self.contract_id
    ProfitBricks::Billing.contract_id
  end
end
