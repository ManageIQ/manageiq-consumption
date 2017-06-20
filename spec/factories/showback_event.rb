FactoryGirl.define do
  factory :showback_event, :class => ManageIQ::Consumption::ShowbackEvent do
    association :resource, :factory => :vm, :strategy => :build_stubbed
    start_time                4.hours.ago
    end_time                  1.hour.ago
    context                   {}
  end
end