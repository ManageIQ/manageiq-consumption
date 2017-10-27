FactoryGirl.define do
  factory :showback_input_measure, :class => ManageIQ::Consumption::ShowbackInputMeasure do
    entity                 'Vm'
    sequence(:description)   { |s| "Description #{s}" }
    group                  'CPU'
    fields               ['average']
  end
end
