class ManageIQ::Consumption::ShowbackCharge < ApplicationRecord
  self.table_name = "showback_charges"
  monetize :cost_subunits

 #belongs_to :showback_event
 #belongs_to :showback_bucket

 #validates :showback_bucket, :presence => true, :allow_nil => false
 #validates :showback_event, :presence => true, :allow_nil => false

  def clean_costs
    self.cost    = nil
    save
  end

  def calculate_costs(price_plan = nil)
    # Find the price plan, there should always be one as it is seeded(Enterprise)
    price_plan ||= showback_bucket.find_price_plan
    cost = price_plan.calculate_cost(showback_event)
    save
    cost
  end
end
