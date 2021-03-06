require 'active_support/core_ext/date'
require 'active_support/core_ext/date_time'
require 'active_support/core_ext/time'
require 'active_support/core_ext/numeric/bytes'
require 'active_support/core_ext/integer/time'
require 'active_support/core_ext/string/conversions'
require 'active_support/core_ext/enumerable'

class ProfitBricks::Billing::TrafficTable

  def self.by_period(period)
    params = {:method => :get,
      :path => "/#{contract_id}/traffic/#{period}",
      :query => {:nic => true},
      :expects => 200}
    body = ProfitBricks::Billing.request params
#      p body
    body['traffic']
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
    gigabytes * 1.gigabyte / 1.megabyte
  end

  def gigabytes
    empty? ? 0.0 : bytes.to_f
  end

  private
  def empty?
    bytes.nil? || bytes.empty?
  end
end

class ProfitBricks::Billing::TrafficRow
  attr_accessor :in_or_out, :dc_id, :dc_name, :days, :period, :nic_id

  def self.by_current_period
    by_period default_period
  end

  def self.by_period_for_date(date)
    by_period period_for date
  end

  LAST_4_PERIODS = 0..4
  def self.by_last_4_periods_and_dc_id(dc_id)
    LAST_4_PERIODS.collect do |n|
      period = period_for n.months.ago
      by_period_and_dc_id period, dc_id
    end
  end

  def self.by_last_4_periods_and_nic_id(nic_id)
    LAST_4_PERIODS.collect do |n|
      period = period_for n.months.ago
      by_period_and_nic_id period, nic_id
    end
  end

  def self.by_last_4_periods
    LAST_4_PERIODS.collect do |n|
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
      when /^NIC$/i
        self.nic_id = line[index]
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
  
  def self.by_period_and_nic_id(period, nic_id)
    by_period(period).select do |traffic|
      traffic.nic_id == nic_id
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
