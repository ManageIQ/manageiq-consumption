FactoryGirl.define do
  factory :showback_rate, :class => ManageIQ::Consumption::ShowbackRate do
    variable_rate        { Money.new(rand(5..2000), 'USD') }
    fixed_rate           { Money.new(rand(5..2000), 'USD') }
    screener	           { { } }
    calculation          'duration'
    sequence(:category)  { |n| "CPU#{n}" }
    sequence(:dimension) { |n| "max_CPU#{n}" }
    sequence(:concept)   { |n| "Concept #{n}" }
    showback_price_plan

    trait :occurrence do
      calculation 'occurrence'
    end
    trait :duration do
      calculation 'duration'
    end
    trait :quantity do
      calculation 'quantity'
    end
  end
end