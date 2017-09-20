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

    def name
      "#{showback_rate.category}:#{showback_rate.measure}:#{showback_rate.dimension}:Tier:#{tier_start_value}-#{tier_end_value}"
    end


  end
end
