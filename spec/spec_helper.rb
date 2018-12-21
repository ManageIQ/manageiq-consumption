if ENV['CI']
  require 'simplecov'
  SimpleCov.start
end

FactoryBot.definition_file_paths << ManageIQ::Showback::Engine.root.join('spec', 'factories')