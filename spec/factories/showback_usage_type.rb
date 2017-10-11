FactoryGirl.define do
  factory :showback_usage_type, :class => ManageIQ::Consumption::ShowbackUsageType do
    category                 'Vm'
    sequence(:description)   { |s| "Description #{s}" }
    measure                  'CPU'
    dimensions               ['average']
  end
end
