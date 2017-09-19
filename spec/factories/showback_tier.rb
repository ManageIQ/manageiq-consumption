FactoryGirl.define do
  factory :showback_tier, :class => ManageIQ::Consumption::ShowbackTier do
    tier_start_value       0
    tier_end_value         Float::INFINITY
    fixed_rate             { Money.new(rand(5..200), 'USD') }
    fixed_rate_per_time    { 'monthly' }
    variable_rate          { Money.new(rand(5..200), 'USD') }
    variable_rate_per_unit 'cores'
    variable_rate_per_time { 'monthly' }
    showback_rate

    trait :daily do
      fixed_rate_per_time {'daily'}
      variable_rate_per_time {'daily'}
    end

    trait :with_rate_tests do
      fixed_rate    { Money.new(11) }
      variable_rate { Money.new(7) }
    end
  end
end