class ManageIQ::Consumption::ShowbackCharge < ApplicationRecord
  self.table_name = "showback_charges"
  monetize :cost_subunits
  default_value_for :cost, 0

  belongs_to :showback_event, :inverse_of => :showback_charges
  belongs_to :showback_pool,  :inverse_of => :showback_charges

  validates :showback_pool,  :presence => true, :allow_nil => false
  validates :showback_event, :presence => true, :allow_nil => false

  def clean_cost
    self.cost = 0
    save
  end

  def calculate_cost(price_plan = nil)
    # Find the price plan, there should always be one as it is seeded(Enterprise)
    price_plan ||= showback_pool.find_price_plan
    if price_plan
      cost = price_plan.calculate_cost(showback_event)
      save
      cost
    else
      errors.add(:showback_price_plan, 'ShowbackPricePlan not found')
      nil
    end
  end
end
