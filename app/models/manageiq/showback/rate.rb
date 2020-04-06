module ManageIQ::Showback
  class Rate < ApplicationRecord
    VALID_RATE_CALCULATIONS = %w(occurrence duration quantity).freeze
    self.table_name = 'showback_rates'

    belongs_to :price_plan, :inverse_of => :rates, :foreign_key => :showback_price_plan_id
    has_many :tiers,
             :inverse_of  => :rate,
             :foreign_key => :showback_rate_id

    validates :calculation, :presence => true, :inclusion => { :in => VALID_RATE_CALCULATIONS }
    validates :entity, :presence => true
    validates :field, :presence => true

    # There is no fixed_rate unit (only presence or not, and time), TODO: change column name in a migration
    validates :group, :presence => true
    default_value_for :group, ''

    default_value_for :screener, { }

    # Variable uses_single_tier to indicate if the rate only apply in the tier where the value is included
    # (defaults to `true`)
    # @return [Boolean]
    default_value_for :uses_single_tier, true

    # Variable tiers_use_full_value
    # (defaults to `true`)
    # @return [Boolean]
    default_value_for :tiers_use_full_value, true

    default_value_for :tier_input_variable, ''

    validates :screener, :exclusion => { :in => [nil] }

    after_create :create_zero_tier

    def name
      "#{entity}:#{group}:#{field}"
    end

    # Create a Zero tier when the rate is create
    # (defaults to `:html`)
    #
    # == Returns:
    # A Tier created with interval 0 - Infinity
    #
    def create_zero_tier
      ManageIQ::Showback::Tier.create(:tier_start_value => 0, :tier_end_value => Float::INFINITY, :rate => self)
    end

    def rate(event, cycle_duration = nil)
      # Find tier (use context)
      # Calculate value within tier
      # For each tier used, calculate costs
      value, groupment = event.get_group(group, field) # Returns group and the unit
      tiers = get_tiers(value || 0)
      duration = cycle_duration || event.month_duration
      # To do event.resource.type should be eq to entity
      acc = 0
      adjusted_value = value # Just in case we need to update it
      # If there is a step defined, we use it to adjust input to it
      tiers.each do |tier|
        # If there is a step defined, we use it to adjust input to it
        unless tier.step_value.nil? || tier.step_unit.nil?
          # Convert step and value to the same unit (variable_rate_per_unit)  and calculate real values with the minimum step)
          adjusted_step = UnitsConverterHelper.to_unit(tier.step_value, tier.step_unit, tier.variable_rate_per_unit)
          tier_start_value = UnitsConverterHelper.to_unit(tier.tier_start_value, tier_input_variable, groupment)
          tier_value = tiers_use_full_value ? value : value - tier_start_value
          divmod = UnitsConverterHelper.to_unit(tier_value, groupment, tier.variable_rate_per_unit).divmod(adjusted_step)
          adjusted_value = (divmod[0] + (divmod[1].zero? ? 0 : 1)) * adjusted_step
          groupment = tier.variable_rate_per_unit # Updated value with new groupment as we have updated values
        end
        # If there is a step time defined, we use it to adjust input to it
        adjusted_time_span = event.time_span
        acc += rate_with_values(tier, adjusted_value, groupment, adjusted_time_span, duration)
      end
      acc
    end

    def rate_with_values(tier, value, group, time_span, cycle_duration, date = Time.current)
      send(calculation.downcase, tier, value, group, time_span, cycle_duration, date)
    end

    private

    def get_tiers(value)
      if uses_single_tier
        tiers.where("tier_start_value <=  ? AND  tier_end_value > ?", value, value)
      else
        tiers.where("tier_start_value <=  ?", value)
      end
    end

    def occurrence(tier, value, _group, _time_span, cycle_duration, date)
      # Returns fixed_cost always + variable_cost sometimes
      # Fixed cost are always added fully, variable costs are only added if value is not nil
      # fix_inter: number of intervals in the calculation => how many times do we need to apply the rate to get a monthly (cycle) rate (min = 1)
      # fix_inter * fixed_rate ==  interval_rate (i.e. monthly)
      # var_inter * variable_rate == interval_rate (i.e. monthly)
      fix_inter = TimeConverterHelper.number_of_intervals(
        :period           => cycle_duration,
        :interval         => tier.fixed_rate_per_time,
        :calculation_date => date
      )
      var_inter = TimeConverterHelper.number_of_intervals(
        :period           => cycle_duration,
        :interval         => tier.variable_rate_per_time,
        :calculation_date => date
      )
      fix_inter * tier.fixed_rate + (value ? var_inter * tier.variable_rate : 0) # fixed always, variable if value
    end

    def duration(tier, value, group, time_span, cycle_duration, date)
      # Returns fixed_cost + variable costs taking into account value and duration
      # Fixed cost and variable costs are prorated on time
      # time_span = end_time - start_time (duration of the event)
      # cycle_duration: duration of the cycle (i.e 1.month, 1.week, 1.hour)
      # fix_inter: number of intervals in the calculation => how many time do we need to apply the rate to get a monthly (cycle) rate (min = 1)
      # fix_inter * fixed_rate ==  interval_rate (i.e. monthly from hourly)
      # var_inter * variable_rate == interval_rate (i.e. monthly variable from hourly)
      return Money.new(0) unless value # If value is null, the event is not present and thus we return 0
      fix_inter = TimeConverterHelper.number_of_intervals(
        :period           => cycle_duration,
        :interval         => tier.fixed_rate_per_time,
        :calculation_date => date
      )
      var_inter = TimeConverterHelper.number_of_intervals(
        :period           => cycle_duration,
        :interval         => tier.variable_rate_per_time,
        :calculation_date => date
      )
      value_in_rate_units = UnitsConverterHelper.to_unit(value.to_f, group, tier.variable_rate_per_unit) || 0
      ((fix_inter * tier.fixed_rate) + (var_inter * value_in_rate_units * tier.variable_rate)) * time_span.to_f / cycle_duration
    end

    def quantity(tier, value, group, _time_span, cycle_duration, date)
      # Returns costs based on quantity (independently of duration).
      # Fixed cost are calculated per period (i.e. 5&euro;/month). You could use occurrence or duration
      # time_span = end_time - start_time
      # cycle_duration: duration of the cycle (i.e 1.month)
      # fix_inter: number of intervals in the calculation => how many time do we need to apply the rate to get a monthly rate
      # fix_inter * fixed_rate ==  interval_rate (i.e. monthly)
      return Money.new(0) unless value # If value is null, the event is not present and thus we return 0
      fix_inter = TimeConverterHelper.number_of_intervals(
        :period           => cycle_duration,
        :interval         => tier.fixed_rate_per_time,
        :calculation_date => date
      )
      value_in_rate_units = UnitsConverterHelper.to_unit(value, group, tier.variable_rate_per_unit) || 0
      (fix_inter * tier.fixed_rate) + (value_in_rate_units * tier.variable_rate)
    end
  end
end
