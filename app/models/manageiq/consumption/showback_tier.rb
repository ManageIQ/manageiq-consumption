module ManageIQ::Consumption
  class ShowbackTier < ApplicationRecord
    self.table_name = 'showback_tiers'
    belongs_to :showback_rate, :inverse_of => :showback_tiers

    # Fixed rate costs
    # (defaults to `0`)
    # @return [Float] the subunits of a fixed rate
    monetize(:fixed_rate_subunits, :with_model_currency => :currency)
    default_value_for :fixed_rate, Money.new(0)

    # Variable rate costs
    # (defaults to `0`)
    # @return [Float] the subunits of a fixed rate
    monetize(:variable_rate_subunits, :with_model_currency => :currency)
    default_value_for :variable_rate, Money.new(0)

    # Fixed rate time apply
    # (defaults to `monthly`)
    # @return [String] a value of VALID_INTERVAL_UNITS = %w(hourly daily weekly monthly yearly)
    validates :fixed_rate_per_time, :inclusion => { :in => TimeConverterHelper::VALID_INTERVAL_UNITS }
    default_value_for :fixed_rate_per_time, 'monthly'

    # Variable rate time apply
    # (defaults to `monthly`)
    # @return [String] a value of VALID_INTERVAL_UNITS = %w(hourly daily weekly monthly yearly)
    validates :variable_rate_per_time, :inclusion => { :in => TimeConverterHelper::VALID_INTERVAL_UNITS }
    default_value_for :variable_rate_per_time, 'monthly'

    validates :variable_rate_per_unit, :presence  => true, :allow_blank => true
    validates :variable_rate_per_unit, :exclusion => { :in => [nil] }
    default_value_for :variable_rate_per_unit, ''

    # Variable tier_start_value is the start value of the tier interval
    # @return [Float]
    validates :tier_start_value, :numericality => {:greater_than_or_equal_to => 0, :less_than => Float::INFINITY}

    # Variable tier_start_value is the end value of the tier interval
    # @return [Float]
    validates :tier_end_value, :numericality => {:greater_than_or_equal_to => 0}

    validate :validate_interval

    # Get a representation string of the object
    #
    # @return [String] the definition of the object
    def name
      "#{showback_rate.entity}:#{showback_rate.group}:#{showback_rate.field}:Tier:#{tier_start_value}-#{tier_end_value}"
    end

    # Validate the interval bvefore save
    #
    # @return Nothing or Error if the interval is in another tier in the same rate
    def validate_interval
      raise _("Start value of interval is greater than end value") unless tier_start_value < tier_end_value
      ManageIQ::Consumption::ShowbackTier.where(:showback_rate => showback_rate).each do |tier|
        # Returns true == overlap, false == no overlap
        next unless self != tier
        if tier.tier_end_value == Float::INFINITY && (tier_start_value > tier.tier_start_value || tier_end_value > tier.tier_start_value)
          raise _("Interval or subinterval is in a tier with Infinity at the end")
        end
        raise _("Interval or subinterval is in another tier") if included?(tier.tier_start_value, tier.tier_end_value)
      end
    end

    # Get the range of the tier in appropiate format
    #
    # (see #set_range)
    # @return [Range] the range of the tier.
    def range
      (tier_start_value..tier_end_value) # or as an array, or however you want to return it
    end

    # Set the range of the tier
    #
    # (see #range)
    def set_range(srange, erange)
      self.tier_start_value = srange
      self.tier_end_value   = erange
      self.save
    end

    # Method to create another tier partition
    # == Parameters:
    # ::value
    #  Is the value to split the tier
    # == Returns:
    # Create the new tier from value to the end of the original tier
    #
    def divide_tier(value)
      old = tier_end_value
      self.tier_end_value = value
      self.save
      new_tier = self.dup
      new_tier.tier_end_value = old
      new_tier.tier_start_value = value
      new_tier.save
    end

    # Method to convert to float the value
    # == Parameters:
    # ::value
    #  Is the value to convert
    # == Returns:
    # Float value
    #
    def self.to_float(s)
      if s.to_s.include?("Infinity")
        Float::INFINITY
      else
        s
      end
    end

    # Check if value is inside the interval of the tier
    # == Parameters:
    # ::value
    #  Is the value to check if is inside
    # == Returns:
    # True if value is included
    # False is not
    #
    def includes?(value)
      starts_with_zero? && value.zero? || value > tier_start_value && value.to_f <= tier_end_value
    end

    # Check if the tier start in ZERO
    #
    # == Returns:
    # True if tier_start value is ZERO
    # False is not
    #
    def starts_with_zero?
      tier_start_value.zero?
    end

    # Check if the tier end in INFINITY
    #
    # == Returns:
    # True if tier_end value is INFINITY
    # False is not
    #
    def ends_with_infinity?
      tier_end_value == Float::INFINITY
    end

    # Check if the tier is free
    #
    # == Returns:
    # True if fixed_rate and variable_rate are zero
    # False is not
    #
    def free?
      fixed_rate.zero? && variable_rate.zero?
    end

    private

    # Check if the tier is included in a interval
    #
    # == Parameters:
    # start_value::
    #  Is the initial value of the interval
    # end_value::
    #  Is the end value of the interval
    # == Returns:
    # True if is included
    # False is not
    #
    def included?(start_value, end_value)
      return false if tier_end_value < start_value
      return false if tier_start_value >= end_value
      true
    end
  end
end
