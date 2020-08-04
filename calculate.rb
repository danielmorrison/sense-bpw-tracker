require "csv"
require "rubygems"
require "active_support/all"

data_root = "/Users/daniel/Documents/99\ W\ 11th/Energy/Sense\ Exports"

def rate_for_time(time)
  if time.on_weekend? || time.hour >= 22 || time.hour < 8 || bpw_holiday?(time)
    # off peak
    "0.0350".to_d
  elsif (10...18).cover?(time.hour)
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

Dir.children(data_root).each do |child|
  CSV.foreach(File.join(data_root, child), "r", headers: true, skip_lines: /^#/) do |row|
    hourlies << row if row["Device ID"] == "mains" && row["Name"] == "Total Usage"
  end
end

hourlies.group_by{|hourly| hourly["DateTime"].split(" ").first }.sort_by{|d, _| d }.each do |day, readings|
  day_savings = readings.sum do |hourly|
    kwh = hourly["kWh"].to_d
    hour = Time.parse(hourly["DateTime"])
    base_rate = mid_peak_for_time(hour) # base rate is equal to mid peak
    tou_rate = rate_for_time(hour)
    savings = (kwh * base_rate) - (kwh * tou_rate) # positive numbers are good
  end

  grand_total += day_savings

  puts "#{day}: $" + day_savings.to_s
end



puts "Total Savings: $#{grand_total}"
