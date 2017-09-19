module ManageIQ::Consumption
  class ShowbackRate < ApplicationRecord
    VALID_RATE_CALCULATIONS = %w(occurrence duration quantity).freeze
    self.table_name = 'showback_rates'

    belongs_to :showback_price_plan, :inverse_of => :showback_rates
    has_many :showback_tiers, :inverse_of => :showback_rate

    validates :calculation, :presence => true, :inclusion => { :in => VALID_RATE_CALCULATIONS }
    validates :category,    :presence => true
    validates :dimension,   :presence => true

    # There is no fixed_rate unit (only presence or not, and time), TODO: change column name in a migration
    validates :measure, :presence => true
    default_value_for :measure, ''

    serialize :screener, JSON # Implement data column as a JSON
    default_value_for :screener, { }
    validates :screener, :exclusion => { :in => [nil] }

    def name
      "#{category}:#{measure}:#{dimension}"
    end

    def rate(event, cycle_duration = nil)
      value, _ = event.get_measure(measure, dimension)  # Returns measure and the unit
      get_tier(value || 0).rate_tier(event,cycle_duration)
    end

    private

    def get_tier(value)
      showback_tiers.where("tier_start_value <=  ? AND  tier_end_value > ?", value, value).first
    end
  end
end
