class ManageIQ::Consumption::ShowbackRate < ManageIQ::Consumption::Rate
  alias_attribute :showback_price_plan, :price_plan
  alias_attribute :showback_tiers, :tiers
end
