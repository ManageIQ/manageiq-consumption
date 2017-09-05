FactoryGirl.define do
  factory :showback_rate, :class => ManageIQ::Consumption::ShowbackRate do
    category               'Vm'
    dimension              'max_number_of_cpu'
    measure                'CPU'
    sequence(:concept)     { |n| "Concept #{n}" }
    fixed_rate             { Money.new(rand(5..200), 'USD') }
    fixed_rate_per_time    { 'monthly' }
    variable_rate          { Money.new(rand(5..200), 'USD') }
    variable_rate_per_unit 'cores'
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
    trait :CPU_average do
      dimension 'average'
      measure 'CPU'
      variable_rate_per_unit 'percent'
    end
    trait :CPU_number do
      measure 'CPU'
      dimension 'number'
      variable_rate_per_unit 'cores'
    end
    trait :CPU_max_number_of_cpu do
      measure 'CPU'
      dimension 'max_number_of_cpu'
      variable_rate_per_unit 'cores'
    end

    trait :MEM_max_mem do
      measure 'MEM'
      dimension 'max_mem'
      variable_rate_per_unit 'Mib'
    end
  end
end