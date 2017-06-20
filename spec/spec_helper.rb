if ENV['CI']
  require 'simplecov'
  SimpleCov.start
end

FactoryGirl.definition_file_paths << ManageIQ::Consumption::Engine.root.join('spec', 'factories')

