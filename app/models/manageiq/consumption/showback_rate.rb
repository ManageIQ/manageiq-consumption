module ManageIQ::Consumption
  class ShowbackRate < ApplicationRecord
    self.table_name = 'showback_rates'
    belongs_to :showback_price_plan, :inverse_of => :showback_rates

    monetize :fixed_rate_subunits,    :with_model_currency => :currency
    monetize :variable_rate_subunits, :with_model_currency => :currency

    validates :calculation, :presence => true, :inclusion => { :in => %w(occurrence duration quantity) }
    validates :category,    :presence => true
    validates :dimension,   :presence => true

    validates :fixed_rate_per_time, :inclusion => { :in => TimeConverterHelper::VALID_INTERVAL_UNITS }
    validates :fixed_rate_per_unit, :presence  => true, :allow_blank => true
    validates :fixed_rate_per_unit, :exclusion => { :in => [nil] }
    default_value_for :fixed_rate_per_unit, ''
    default_value_for :fixed_rate_per_time, 'monthly'

    validates :variable_rate_per_time, :inclusion => { :in => TimeConverterHelper::VALID_INTERVAL_UNITS }
    validates :variable_rate_per_unit, :presence  => true, :allow_blank => true
    validates :variable_rate_per_unit, :exclusion => { :in => [nil] }
    default_value_for :variable_rate_per_unit, ''
    default_value_for :variable_rate_per_time, 'monthly'

    serialize :screener, JSON # Implement data column as a JSON
    default_value_for :screener, { }

    def name
      "#{category}:#{dimension}"
    end

    def rate(value, event)
      # Find tier (use context)
      # Calculate value within tier
      # For each tier used, calculate costs
      rate_with_values(value || 0, event.time_span, event.month_duration)
    end

    def rate_with_values(value, time_span, cycle_duration, date = Time.now)
      send(calculation.downcase, value || 0, time_span, cycle_duration, date)
    end

    private

    def occurrence(_value, time_span, cycle_duration, date)
      # Returns fixed_cost + variable_cost prorated on time
      # Fixed cost are always added fully, variable costs are prorated on the cycle duration
      # time_span = end_time - start_time
      # cycle_duration: duration of the cycle (i.e 1.month)
      # fix_inter: number of intervals in the calculation => how many time do we need to apply the rate to get a monthly rate
      # fix_inter * fixed_rate ==  interval_rate (i.e. monthly)
      # var_inter * variable_rate == interval_rate (i.e. monthly variable)
      fix_inter = TimeConverterHelper.number_of_intervals(cycle_duration, fixed_rate_per_time, date)
      var_inter = TimeConverterHelper.number_of_intervals(cycle_duration, variable_rate_per_time, date)
      fix_inter * fixed_rate + (var_inter * variable_rate * time_span.to_f / cycle_duration)
    end

    def duration(value, time_span, cycle_duration, date)
      # Returns fixed_cost + event_measure * variable_cost * (end_time - start_time) / total_time
      # Fixed cost and variable costs are prorated on time
      # time_span = end_time - start_time
      # cycle_duration: duration of the cycle (i.e 1.month)
      # fix_inter: number of intervals in the calculation => how many time do we need to apply the rate to get a monthly rate
      # fix_inter * fixed_rate ==  interval_rate (i.e. monthly)
      # var_inter * variable_rate == interval_rate (i.e. monthly variable)
      fix_inter = TimeConverterHelper.number_of_intervals(cycle_duration, fixed_rate_per_time, date)
      var_inter = TimeConverterHelper.number_of_intervals(cycle_duration, variable_rate_per_time, date)
      (fix_inter * fixed_rate * time_span.to_f / cycle_duration) + (var_inter * value * variable_rate * time_span.to_f / cycle_duration)
    end

    def quantity(value, time_span, cycle_duration, date)
      # Returns costs based on quantity (independently of duration)
      # [event.fixed_cost, event_measure * variable_cost]
      # Fixed cost and variable costs are prorated on time
      # time_span = end_time - start_time
      # cycle_duration: duration of the cycle (i.e 1.month)
      # fix_inter: number of intervals in the calculation => how many time do we need to apply the rate to get a monthly rate
      # fix_inter * fixed_rate ==  interval_rate (i.e. monthly)
      # var_inter * variable_rate == interval_rate (i.e. monthly variable)
      fix_inter = TimeConverterHelper.number_of_intervals(cycle_duration, fixed_rate_per_time, date)
      var_inter = TimeConverterHelper.number_of_intervals(cycle_duration, variable_rate_per_time, date)
      (fix_inter * fixed_rate * time_span.to_f / cycle_duration) + (var_inter * value * variable_rate)
    end
  end
end
