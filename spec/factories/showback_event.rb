FactoryGirl.define do
  factory :showback_event, :class => ManageIQ::Consumption::ShowbackEvent do
    association :resource, :factory => :vm, :strategy => :build_stubbed
    start_time                4.hours.ago
    end_time                  1.hour.ago
    context                   {}
    data { { } }

    trait :full_month do
      start_time  DateTime.now.utc.beginning_of_month
      end_time    DateTime.now.utc.end_of_month
    end

    trait :with_vm_data do
      data { { "CPU" => { "average" => 52.67, "max_number_of_cpu" => 4 } } }
    end

    trait :first_half_month do
      start_time     DateTime.now.utc.beginning_of_month
      end_time       DateTime.now.utc.change(:day => 15).end_of_day
    end
  end
end