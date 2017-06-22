class ManageIQ::Consumption::ShowbackRate < ApplicationRecord
  self.table_name = "showback_rates"
  belongs_to :showback_price_plan, :inverse_of => :showback_rates

  monetize :fixed_rate_subunits
  monetize :variable_rate_subunits

  validates :calculation,:presence => true
  validates :category,   :presence => true
  validates :dimension,  :presence => true
  validates :screener,   :presence => true, :allow_blank => true


end