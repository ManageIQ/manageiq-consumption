FactoryBot.define do
  factory :input_measure, :class => ManageIQ::Showback::InputMeasure do
    entity                   { 'Vm' }
    sequence(:description)   { |s| "Description #{s}" }
    group                    { 'CPU' }
    fields                   { ['average'] }
  end
end
