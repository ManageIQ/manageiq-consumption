FactoryGirl.define do
  factory :showback_rate, :class => ManageIQ::Consumption::ShowbackRate do
    variable_rate        { Money.new(rand(5..20), 'USD') }
    fixed_rate           { Money.new(rand(5..20), 'USD') }
    calculation          "Duration"
    screener	         {{}}
    sequence(:category)  { |n| "CPU#{n}" }
    sequence(:dimension) { |n| "max_CPU#{n}" }
    sequence(:concept)   { |n| "Concept #{n}" }
    showback_price_plan
  end
end