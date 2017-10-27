FactoryGirl.define do
  factory :input_measure, :class => ManageIQ::Consumption::InputMeasure do
    entity                   'Vm'
    sequence(:description)   { |s| "Description #{s}" }
    group                    'CPU'
    fields                   ['average']
  end
end
