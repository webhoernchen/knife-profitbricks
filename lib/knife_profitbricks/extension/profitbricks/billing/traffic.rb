require 'active_support/core_ext/date'
require 'active_support/core_ext/date_time'
require 'active_support/core_ext/time'
require 'active_support/core_ext/numeric/bytes'
require 'active_support/core_ext/integer/time'
require 'active_support/core_ext/string/conversions'
require 'active_support/core_ext/enumerable'

class ProfitBricks::Billing::TrafficTable

  def self.by_period(period)
    @periods ||= {}

    if r = @periods[period]
      r
    else
      body = ProfitBricks::Billing.request(:method => :get,
      :path => "/#{contract_id}/traffic/#{period}",
      :query => {:mac => true},
      :expects => 200)
#      p body
      body['traffic']
    end
  rescue Excon::Errors::NotFound
    []
  rescue Exception => e
    p "Traffic for period '#{period}' can not be displayed: #{e.class} - #{e.to_s}"
    []
  end

  private
  def self.request(params)
    ProfitBricks::Billing.request params
  end
  
  def self.contract_id
    ProfitBricks::Billing.contract_id
  end
end

class ProfitBricks::Billing::TrafficDay
  attr_accessor :number_of_day, :bytes

  def megabytes
   bytes.to_i.to_f / 1.megabyte if bytes
  end

  def gigabytes
   bytes.to_i.to_f / 1.gigabyte if bytes
  end
end

class ProfitBricks::Billing::TrafficRow
  attr_accessor :in_or_out, :dc_id, :dc_name, :days, :period, :mac

  def self.by_current_period
    by_period default_period
  end

  def self.by_period_for_date(date)
    by_period period_for date
  end

  def self.by_last_4_periods_and_dc_id(dc_id)
    (0..4).collect do |n|
      period = period_for n.months.ago
      by_period_and_dc_id period, dc_id
    end
  end

  def self.by_last_4_periods_and_mac(mac)
    (0..4).collect do |n|
      period = period_for n.months.ago
      by_period_and_mac period, mac
    end
  end

  def self.by_last_4_periods
    (0..4).collect do |n|
      by_period_for_date n.months.ago
    end
  end

  def initialize(meta_line, line)
    line = line.split(',')

    meta_line.split(',').each_with_index do |attr_name, index|
      case attr_name
      when /^IN\/OUT$/i
        self.in_or_out = line[index]
      when /^VDC\ UUID$/i
        self.dc_id = line[index]
      when /^VDC\ NAME$/i
        self.dc_name = line[index]
      when /^[0-9]{4}(-[0-9]{2}){2}$/
        self.period = attr_name.split('-')[0..1].join('.')
        self.days ||= {}
        number_of_day = attr_name.split('-').last.to_i
        day = self.days[number_of_day] = ProfitBricks::Billing::TrafficDay.new
        day.number_of_day = number_of_day
        day.bytes = line[index]
#        day.bytes = 0 unless day.bytes
      when /^MAC$/i
        self.mac = line[index]
      end
    end
  end

  def megabytes
    days.values.collect(&:megabytes).compact.sum
  end

  def gigabytes
    days.values.collect(&:gigabytes).compact.sum
  end

  private
  def self.by_period(period)
    (@cached_by_period ||= {})[period] ||= uncached_by_period period
  end

  def self.uncached_by_period(period)
    table_rows = ProfitBricks::Billing::TrafficTable.by_period period
    meta_line = table_rows.first

    if meta_line.nil?
      []
    else
      table_rows[1..-1].collect do |line|
        new meta_line, line
      end
    end
  end
  
  def self.by_period_and_dc_id(period, dc_id)
    by_period(period).select do |traffic|
      traffic.dc_id == dc_id
    end
  end
  
  def self.by_period_and_mac(period, mac)
    by_period(period).select do |traffic|
      traffic.mac == mac
    end
  end

  def self.previous_period
    period_for 1.month.ago
  end

  def self.default_period
    period_for Date.today
  end

  def self.period_for(date)
    date.strftime '%Y-%m'
  end
end
