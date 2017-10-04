module ManageIQ::Consumption
  class ShowbackTier < ApplicationRecord

    self.table_name = 'showback_tiers'
    belongs_to :showback_rate, :inverse_of => :showback_tiers

    # Fixed rate costs
    # (defaults to `0`)
    # @return [Float] the subunits of a fixed rate
    monetize :fixed_rate_subunits,    :with_model_currency => :currency
    default_value_for :fixed_rate,  Money.new(0)

    # Variable rate costs
    # (defaults to `0`)
    # @return [Float] the subunits of a fixed rate
    monetize :variable_rate_subunits, :with_model_currency => :currency
    default_value_for :variable_rate,  Money.new(0)

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

    validates :tier_start_value,  :numericality => {:greater_than_or_equal_to => 0, :less_than => Float::INFINITY}
    validates :tier_end_value,    :numericality => {:greater_than_or_equal_to => 0}

    validate :validate_interval

    # Returns the logical name of the object associated with his showback_rate.
    #
    # @return [String] category_of_rate:measure_name:dimension_of_measure:Tier:start_value-end_value.
    def name
      "#{showback_rate.category}:#{showback_rate.measure}:#{showback_rate.dimension}:Tier:#{tier_start_value}-#{tier_end_value}"
    end

    def validate_interval
      ManageIQ::Consumption::ShowbackTier.where(:showback_rate => showback_rate).each do |tier|
        #returns true == overlap, false == no overlap
        puts self.inspect
        puts tier.inspect
        if tier.tier_end_value == Float::INFINITY and (tier_start_value>tier.tier_start_value or tier_end_value>tier.tier_start_value)
          raise _("Interval or subinterval is in a tier with Infinity at the end")
        end
        if !(range.to_set & tier.range.to_set).empty?
          raise _("Interval or subinterval is in another tier")
        end
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

    def divide_tier(value)
      old = tier_end_value
      self.tier_end_value = value
      self.save
      new_tier = self.dup
      new_tier.tier_end_value = old
      new_tier.tier_start_value = value
      new_tier.save
      puts self.inspect
      puts new_tier.inspect

    end

    def self.to_float(s)
      if s.to_s.include?("Infinity")
        Float::INFINITY
      else
        s
      end
    end

    def includes?(value)
      starts_with_zero? && value.zero? || value > tier_start_value && value.to_f <= tier_end_value
    end

    def starts_with_zero?
      tier_start_value.zero?
    end

    def ends_with_infinity?
      tier_end_value == Float::INFINITY
    end

    def free?
      fixed_rate.zero? && variable_rate.zero?
    end
  end
end
