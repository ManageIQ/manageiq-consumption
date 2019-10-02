FactoryBot.define do
  factory :rate, :class => ManageIQ::Showback::Rate do
    entity                 { 'Vm' }
    field                  { 'max_number_of_cpu' }
    group                  { 'CPU' }
    sequence(:concept)     { |n| "Concept #{n}" }
    screener               { {} }
    calculation            { 'duration' }
    price_plan

    trait :occurrence do
      calculation { 'occurrence' }
    end
    trait :duration do
      calculation { 'duration' }
    end
    trait :quantity do
      calculation { 'quantity' }
    end
    trait :with_screener do
      screener do
        {
          'tag' => {
            'environment' => ['test']
          }
        }
      end
    end
    trait :CPU_average do
      group { 'CPU' }
      field { 'average' }
    end
    trait :CPU_number do
      group { 'CPU' }
      field { 'number' }
    end
    trait :CPU_max_number_of_cpu do
      group { 'CPU' }
      field { 'max_number_of_cpu' }
    end

    trait :MEM_max_mem do
      group { 'MEM' }
      field { 'max_mem' }
    end
  end
end
