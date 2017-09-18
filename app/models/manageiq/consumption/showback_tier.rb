module ManageIQ::Consumption
  class ShowbackTier < ApplicationRecord

    self.table_name = 'showback_tiers'
    belongs_to :showback_rate

    monetize :fixed_rate_subunits,    :with_model_currency => :currency
    monetize :variable_rate_subunits, :with_model_currency => :currency

    validates :fixed_rate_per_time, :inclusion => { :in => TimeConverterHelper::VALID_INTERVAL_UNITS }
    default_value_for :fixed_rate_per_time, 'monthly'

    validates :variable_rate_per_time, :inclusion => { :in => TimeConverterHelper::VALID_INTERVAL_UNITS }
    default_value_for :variable_rate_per_time, 'monthly'

    validates :variable_rate_per_unit, :presence  => true, :allow_blank => true
    default_value_for :variable_rate_per_unit, ''

    validates :variable_rate_per_unit, :exclusion => { :in => [nil] }

    validates :step_unit, :numericality => { :only_integer => true, :greater_than => 0, allow_nil: true}

    validates :tier_start_value,  :numericality => {:greater_than_or_equal_to => 0, :less_than => Float::INFINITY}
    validates :tier_end_value,    :numericality => {:greater_than_or_equal_to => 0}

    def name
      "#{showback_rate.category}:#{showback_rate.measure}:#{showback_rate.dimension}"
    end
  end
end
