module ManageIQ::Consumption
  class ShowbackRate < ApplicationRecord
    VALID_RATE_CALCULATIONS = %w(occurrence duration quantity).freeze
    self.table_name = 'showback_rates'

    belongs_to :showback_price_plan, :inverse_of => :showback_rates
    has_many :showback_tiers

    validates :calculation, :presence => true, :inclusion => { :in => VALID_RATE_CALCULATIONS }
    validates :category,    :presence => true
    validates :dimension,   :presence => true

    # There is no fixed_rate unit (only presence or not, and time), TODO: change column name in a migration
    validates :measure, :presence => true
    default_value_for :measure, ''

    serialize :screener, JSON # Implement data column as a JSON
    default_value_for :screener, { }
    validates :screener, :exclusion => { :in => [nil] }

    after_create :create_zero_tier

    def create_zero_tier
      ManageIQ::Consumption::ShowbackTier.create(:tier_start_value => 0,:tier_end_value => Float::INFINITY) unless ManageIQ::Consumption::ShowbackTier.exists?(:showback_rate => self)
    end

    def name
      "#{category}:#{measure}:#{dimension}"
    end

    def rate(event, cycle_duration = nil)
      # Find tier (use context)
      # Calculate value within tier
      # For each tier used, calculate costs
      duration = cycle_duration || event.month_duration
      # TODO event.resource.type should be eq to category
      value, measurement = event.get_measure(measure, dimension)  # Returns measure and the unit
      sh = get_tier(value)
      adjusted_value = value # Just in case we need to update it
      # If there is a step defined, we use it to adjust input to it
      unless sh.step_value.nil? || sh.step_unit.nil?
        # Convert step and value to the same unit (variable_rate_per_unit)  and calculate real values with the minimum step)
        adjusted_step = UnitsConverterHelper.to_unit(sh.step_value, sh.step_unit, sh.variable_rate_per_unit)
        divmod = UnitsConverterHelper.to_unit(value, measurement, variable_rate_per_unit).divmod adjusted_step
        adjusted_value = (divmod[0] + (divmod[1].zero? ? 0 : 1)) * adjusted_step
        measurement = sh.variable_rate_per_unit # Updated value with new measurement as we have updated values
      end
      # If there is a step time defined, we use it to adjust input to it
      adjusted_time_span = event.time_span
      rate_with_values(adjusted_value, measurement, adjusted_time_span, duration)
    end

    def rate_with_values(value, measure, time_span, cycle_duration, date = Time.current)
      send(calculation.downcase, value, measure, time_span, cycle_duration, date)
    end

    private

    def get_tier(value)
      puts self.inspect
      puts showback_tiers.inspect
      puts value
      puts showback_tiers.first.tier_start_value<value
      puts showback_tiers.first.tier_end_value>value
      showback_tiers.where("tier_start_value <=  ? AND  tier_end_value > ?", value, value).first
    end

    def occurrence(value, _measure, _time_span, cycle_duration, date)
      # Returns fixed_cost always + variable_cost sometimes
      # Fixed cost are always added fully, variable costs are only added if value is not nil
      # fix_inter: number of intervals in the calculation => how many times do we need to apply the rate to get a monthly (cycle) rate (min = 1)
      # fix_inter * fixed_rate ==  interval_rate (i.e. monthly)
      # var_inter * variable_rate == interval_rate (i.e. monthly)
      sh = get_tier(value)
      fix_inter = TimeConverterHelper.number_of_intervals(period: cycle_duration, interval: sh.fixed_rate_per_time, calculation_date: date)
      var_inter = TimeConverterHelper.number_of_intervals(period: cycle_duration, interval: sh.variable_rate_per_time, calculation_date:date)
      fix_inter * sh.fixed_rate + (value ? var_inter * sh.variable_rate : 0) # fixed always, variable if value
    end

    def duration(value, measure, time_span, cycle_duration, date)
      # Returns fixed_cost + variable costs taking into account value and duration
      # Fixed cost and variable costs are prorated on time
      # time_span = end_time - start_time (duration of the event)
      # cycle_duration: duration of the cycle (i.e 1.month, 1.week, 1.hour)
      # fix_inter: number of intervals in the calculation => how many time do we need to apply the rate to get a monthly (cycle) rate (min = 1)
      # fix_inter * fixed_rate ==  interval_rate (i.e. monthly from hourly)
      # var_inter * variable_rate == interval_rate (i.e. monthly variable from hourly)
      sh = get_tier(value)
      return Money.new(0) unless value # If value is null, the event is not present and thus we return 0
      fix_inter = TimeConverterHelper.number_of_intervals(period: cycle_duration, interval: sh.fixed_rate_per_time, calculation_date: date)
      var_inter = TimeConverterHelper.number_of_intervals(period: cycle_duration, interval: sh.variable_rate_per_time, calculation_date: date)
      value_in_rate_units = UnitsConverterHelper.to_unit(value, measure, sh.variable_rate_per_unit) || 0
      ((fix_inter * sh.fixed_rate) + (var_inter * value_in_rate_units * sh.variable_rate)) * time_span.to_f / cycle_duration
    end

    def quantity(value, measure, _time_span, cycle_duration, date)
      # Returns costs based on quantity (independently of duration).
      # Fixed cost are calculated per period (i.e. 5€/month). You could use occurrence or duration
      # time_span = end_time - start_time
      # cycle_duration: duration of the cycle (i.e 1.month)
      # fix_inter: number of intervals in the calculation => how many time do we need to apply the rate to get a monthly rate
      # fix_inter * fixed_rate ==  interval_rate (i.e. monthly)
      sh = get_tier(value)
      return Money.new(0) unless value # If value is null, the event is not present and thus we return 0
      fix_inter = TimeConverterHelper.number_of_intervals(period: cycle_duration, interval: sh.fixed_rate_per_time, calculation_date: date)
      value_in_rate_units = UnitsConverterHelper.to_unit(value, measure, sh.variable_rate_per_unit) || 0
      (fix_inter * sh.fixed_rate) + (value_in_rate_units * sh.variable_rate)
    end
  end
end
