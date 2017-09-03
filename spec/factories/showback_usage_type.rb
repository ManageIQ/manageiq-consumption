FactoryGirl.define do
  factory :showback_usage_type, :class => ManageIQ::Consumption::ShowbackUsageType do
    category                 'Vm'
    sequence(:description)   { |s| "Description #{s}" }
    measure                  'CPU'
    dimensions               ["sb_max_cpu_total_cores","sb_usage_rate_average", "num_cpu","cpu_total_cores","cpu_cores_per_socket"]
  end
end