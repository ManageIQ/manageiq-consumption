module ManageIQ::Consumption
  class ShowbackTier < ApplicationRecord

    self.table_name = 'showback_tiers'
    belongs_to :showback_rate, :inverse_of => :showback_tiers

    monetize :fixed_rate_subunits,    :with_model_currency => :currency
    default_value_for :fixed_rate,  Money.new(0)

    monetize :variable_rate_subunits, :with_model_currency => :currency
    default_value_for :variable_rate,  Money.new(0)

    validates :fixed_rate_per_time, :inclusion => { :in => TimeConverterHelper::VALID_INTERVAL_UNITS }
    default_value_for :fixed_rate_per_time, 'monthly'

    validates :variable_rate_per_time, :inclusion => { :in => TimeConverterHelper::VALID_INTERVAL_UNITS }
    default_value_for :variable_rate_per_time, 'monthly'

    validates :variable_rate_per_unit, :presence  => true, :allow_blank => true
    validates :variable_rate_per_unit, :exclusion => { :in => [nil] }
    default_value_for :variable_rate_per_unit, ''

    validates :tier_start_value,  :numericality => {:greater_than_or_equal_to => 0, :less_than => Float::INFINITY}
    validates :tier_end_value,    :numericality => {:greater_than_or_equal_to => 0}

    before_save :validate_interval

    def name
      "#{showback_rate.category}:#{showback_rate.measure}:#{showback_rate.dimension}:Tier:#{tier_start_value}-#{tier_end_value}"
    end

    def validate_interval
      ManageIQ::Consumption::ShowbackTier.where(:showback_rate => showback_rate).each do |tier|
        next if tier == self
        #returns true == overlap, false == no overlap
        if tier.tier_end_value == Float::INFINITY and (tier_start_value>tier.tier_start_value or tier_end_value>tier.tier_start_value)
          raise _("Interval or subinterval is in a tier with Infinity at the end")
        end
        if !(range.to_set & tier.range.to_set).empty?
          raise _("Interval or subinterval is in another tier")
        end
      end
    end

    def range
      (tier_start_value..tier_end_value) # or as an array, or however you want to return it
    end

    def set_range(srange, erange)
      self.tier_start_value = srange
      self.tier_end_value   = erange
      self.save
    end

    def divide_tier(value)
      old = tier_end_value
      self.tier_end_value = value
      self.save
      new_tier = self.clone
      new_tier.tier_end_value = old
      new_tier.tier_start_value = value
      new_tier.save
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
