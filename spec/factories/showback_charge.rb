FactoryGirl.define do
  factory :showback_charge, :class => ManageIQ::Consumption::ShowbackCharge do
    #showback_bucket
    #showback_event
    cost 0
  end
end