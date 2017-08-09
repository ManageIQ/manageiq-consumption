#
# Helper for unit converters
#
# Allows the user to find distance between prefixes, and also to convert between units.
# It also allows the user to extract the prefix from a unit 'Mb' -> 'M'
#
#

module ManageIQ::Consumption
  module TimeConverterHelper
    VALID_INTERVAL_UNITS = %w(hourly daily weekly monthly yearly).freeze

    def self.number_of_intervals(start_time, end_time, interval, calculation_date = Time.now)
      time_span = case interval
                  when 'minutely' then 1.minute.seconds
                  when 'hourly'   then 1.hour.seconds
                  when 'daily'    then 1.day.seconds
                  when 'weekly'   then 1.week.seconds
                  when 'monthly'  then Time.days_in_month(calculation_date.month)* 1.day.seconds
                  when 'yearly'   then Time.days_in_year(calculation_date.year) * 1.day.seconds
                  end
      (end_time - start_time).div time_span
    end

  end
end