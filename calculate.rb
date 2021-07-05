require "csv"
require "rubygems"
require "active_support/all" # I'm so lazy!

# Export Hourly reports from Sense
# 1. Go to https://home.sense.com/trends
# 2. Select a month
# 3. Click the icon in the upper right that sort of looks like sharing
# 4. Select "Hour" for the interval.
# Set data_root to where you put these files.
data_root = "/Users/daniel/Documents/99\ W\ 11th/Energy/Sense\ Exports"
billing_day = 22

def off_peak?(time)
  time.on_weekend? || time.hour >= 22 || time.hour < 8 || bpw_holiday?(time)
end

def on_peak?(time)
  (10...18).cover?(time.hour) && !off_peak?(time)
end

def rate_for_time(time)
  if off_peak?(time)
    # off peak
    "0.0350".to_d
  elsif on_peak?(time)
    # on peak
    "0.12".to_d
  else
    # mid-peak
    mid_peak_for_time(time)
  end
end

def mid_peak_for_time(time)
  if (5...10).cover?(time.month)
    # mid-peak May-Oct
    "0.0637".to_d
  else
    # mid-peak Nov-Apr
    "0.0520".to_d
  end
end

def bpw_holiday?(time)
  return true if time.month == 1 && time.day == 1 # New Year
  return true if time.month == 5 && time.wday == 1 && (22..28).cover?(time.day) # Memorial day - Last Monday in May
  return true if time.month == 7 && time.day == 4 # July 4
  return true if time.month == 9 && time.wday == 1 && (1..7).cover?(time.day) # Labor day - First Monday in Sept
  return true if time.month == 11 && time.wday == 4 && (22..28).cover?(time.day) # Thanksgiving - 4th Thursday in Nov
  return true if time.month == 12 && time.day == 25 # Christmas

  false
end

grand_total = 0.to_d

hourlies = []

Dir.glob("*.csv", base: data_root).each do |file|
  CSV.foreach(File.join(data_root, file), "r", headers: true, skip_lines: /^#/) do |row|
    hourlies << row if row["Device ID"] == "mains" && row["Name"] == "Total Usage"
  end
end

hourlies.group_by{|hourly| hourly["DateTime"].split(" ").first }.sort_by{|d, _| d }.each do |day, readings|
  kwh_sum = 0
  day_savings = readings.sum do |hourly|
    kwh = hourly["kWh"].to_d
    kwh_sum += kwh
    hour = Time.parse(hourly["DateTime"])
    base_rate = mid_peak_for_time(hour) # base rate is equal to mid peak
    tou_rate = rate_for_time(hour)
    savings = (kwh * base_rate) - (kwh * tou_rate) # positive numbers are good
  end

  grand_total += day_savings

  puts "#{day}: #{kwh_sum}kWh, $" + day_savings.to_s
end

puts "Total Savings: $#{grand_total}"

puts "-" * 20
puts "Date, Off, On, Mid, Savings"
# Billing period stuff
groups = hourlies.group_by do |reading|
  date = reading["DateTime"].split(" ").first.to_date
  start_date = date.change(day: billing_day)
  if date.day >= billing_day
    start_date..start_date.advance(months: 1)
  else
    start_date.advance(months: -1)..start_date
  end
end

groups.sort_by{|range, _| range.first }.each do |range, readings|
  off_peak_kwh = 0.to_d
  on_peak_kwh  = 0.to_d
  mid_peak_kwh = 0.to_d
  base_cost = 0
  tou_cost = 0
  readings.each do |reading|
    time = Time.parse(reading["DateTime"])
    kwh = reading["kWh"].to_d
    if off_peak?(time)
      off_peak_kwh += kwh
    elsif on_peak?(time)
      on_peak_kwh += kwh
    else
      mid_peak_kwh += kwh
    end
    base_cost += (kwh * mid_peak_for_time(time))
    tou_cost += (kwh * rate_for_time(time))
  end
  savings = base_cost - tou_cost
  puts "#{range}, #{off_peak_kwh}, #{on_peak_kwh}, #{mid_peak_kwh}, $#{savings}"
end