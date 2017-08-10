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
      # total_time = calculate_total_time(event)
      # [event.fixed_cost, variable_cost * (end_time - start_time) / total_time]
      fix_inter = TimeConverterHelper.number_of_intervals(time_span, fixed_rate_per_time, date)
      var_inter = TimeConverterHelper.number_of_intervals(time_span, variable_rate_per_time, date)
      fix_inter * fixed_rate + (var_inter * variable_rate * time_span.to_f / cycle_duration)
    end

    def duration(value, time_span, cycle_duration, _date)
      # Returns fixed_cost + event_measure * variable_cost * (end_time - start_time) / total_time
      # total_time = calculate_total_time(event)
      # [event.fixed_cost, event_measure * (event.end_time - event.start_time) / total_time]
      (fixed_rate * time_span.to_f / cycle_duration) + (value * variable_rate * time_span.to_f / cycle_duration)
    end

    def quantity(value, time_span, cycle_duration, _date)
      # event.fixed_cost + variable_cost * event
      # [event.fixed_cost, event_measure * variable_cost]
      (fixed_rate * time_span.to_f / cycle_duration) + (value * variable_rate)
    end
  end
end
