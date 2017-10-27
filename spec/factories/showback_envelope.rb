FactoryGirl.define do
  factory :showback_envelope, :class => ManageIQ::Consumption::ShowbackEnvelope do
    sequence(:name)           { |n| "factory_pool_#{seq_padded_for_sorting(n)}" }
    sequence(:description)    { |n| "pool_description_#{seq_padded_for_sorting(n)}" }
    start_time                4.hours.ago
    end_time                  1.hour.ago
    state                     'OPEN'
    association :resource, :factory => :miq_enterprise, :strategy => :build_stubbed

    trait :processing do
      state 'PROCESSING'
    end

    trait :closed do
      state 'CLOSED'
    end
  end
end
