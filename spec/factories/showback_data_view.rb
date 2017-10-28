FactoryGirl.define do
  factory :showback_data_view, :class => ManageIQ::Consumption::ShowbackDataView do
    showback_envelope
    data_rollup
    cost 0
    data_snapshot { { } }
    context_snapshot { { } }

    trait :with_data_snapshot do
      data_snapshot do
        {
          Time.now.utc.beginning_of_month           => {
            "CPU"    => {
              "average"           => [39.859, "percent"],
              "number"            => [2.0, "cores"],
              "max_number_of_cpu" => [2, "cores"]
            },
            "MEM"    => {
              "max_mem" => [2048, "Mib"]
            },
            "FLAVOR" => {}
          },
          Time.now.utc.beginning_of_month + 15.days => {
            "CPU"    => {
              "average"           => [49.8571428571429, "percent"],
              "number"            => [4.0, "cores"],
              "max_number_of_cpu" => [4, "cores"]
            },
            "MEM"    => {
              "max_mem" => [8192, "Mib"]
            },
            "FLAVOR" => {}
          }
        }
      end
    end
  end
end
