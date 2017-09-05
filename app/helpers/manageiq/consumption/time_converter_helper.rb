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

    def self.number_of_intervals(period:, interval:, calculation_date: Time.now, days_in_month: nil, days_in_year: nil)
      # Period: time period as input (end_time - start_time)
      # interval: base interval to calculate against (i.e 'daily', 'monthly', default: 'monthly')
      # Calculation_date: used to calculate taking into account the #days in month
      # It always return at least 1 as the event exists
      return 1 if period.zero?
      time_span = case interval
                  when 'minutely' then 1.minute.seconds
                  when 'hourly'   then 1.hour.seconds
                  when 'daily'    then 1.day.seconds
                  when 'weekly'   then 1.week.seconds
                  when 'monthly'  then (days_in_month || Time.days_in_month(calculation_date.month)) * 1.day.seconds
                  when 'yearly'   then (days_in_year || Time.days_in_year(calculation_date.year)) * 1.day.seconds
                  end
      period.div(time_span) + (period.modulo(time_span).zero? ? 0 : 1)
    end

  end
end