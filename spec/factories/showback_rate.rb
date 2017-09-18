FactoryGirl.define do
  factory :showback_rate, :class => ManageIQ::Consumption::ShowbackRate do
    category               'Vm'
    dimension              'max_number_of_cpu'
    measure                'CPU'
    sequence(:concept)     { |n| "Concept #{n}" }
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
      measure 'CPU'
      dimension 'average'
    end
    trait :CPU_number do
      measure 'CPU'
      dimension 'number'
    end
    trait :CPU_max_number_of_cpu do
      measure 'CPU'
      dimension 'max_number_of_cpu'
    end

    trait :MEM_max_mem do
      measure 'MEM'
      dimension 'max_mem'
    end
  end
end