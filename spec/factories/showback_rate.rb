FactoryGirl.define do
  factory :showback_rate, :class => ManageIQ::Consumption::ShowbackRate do
    category               'Vm'
    dimension              { %w[CPU#average CPU#number CPU#max_number_of_cpu].sample }
    sequence(:concept)     { |n| "Concept #{n}" }
    fixed_rate             { Money.new(rand(5..200), 'USD') }
    fixed_rate_per_unit    do
      case dimension
      when "CPU#average"
        'percent'
      when "CPU#number"
        'cores'
      when "CPU#max_number_of_cpu"
        'cores'
      end
    end
    fixed_rate_per_time    { 'monthly' }
    variable_rate          { Money.new(rand(5..200), 'USD') }
    variable_rate_per_unit    do
      case dimension
      when "CPU#average"
        'percent'
      when "CPU#number"
        'cores'
      when "CPU#max_number_of_cpu"
        'cores'
      end
    end
    variable_rate_per_time { 'monthly' }
    screener               { {} }
    calculation            'duration'
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

    trait :with_screener do
      screener { { 'tag' => { 'environment' => ['test'] } } }
    end
  end
end