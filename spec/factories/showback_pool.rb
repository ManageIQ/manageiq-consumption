FactoryGirl.define do
  factory :showback_pool, :class => ManageIQ::Consumption::ShowbackPool do
    sequence(:name)           { |n| "factory_pool_#{seq_padded_for_sorting(n)}" }
    sequence(:description)    { |n| "pool_description_#{seq_padded_for_sorting(n)}" }
    start_time                4.hours.ago
    end_time                  1.hour.ago
    state                     "OPEN"
    association :resource, :factory => :miq_enterprise, :strategy => :build_stubbed
  end

  factory :showback_pool_processing, :parent => :showback_pool do
    state "PROCESSING"
  end

  factory :showback_pool_close, :parent => :showback_pool do
    state "CLOSE"
  end
end