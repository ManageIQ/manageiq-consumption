if ENV['CI']
  require 'simplecov'
  SimpleCov.start
end

require 'manageiq-consumption'



Dir[ManageIQ::Consumption::Engine.root.join("spec/support/**/*.rb")].each { |f| require f }

require 'factory_girl'
# in case we are running as an engine, the factories are located in the dummy app
FactoryGirl.definition_file_paths << 'plugins/manageiq-consumption/spec/factories/'
# also add factories from provider gems until miq codebase does not use any provider specific factories anymore
Rails::Engine.subclasses.select { |e| e.name.starts_with?("ManageIQ::Consumption::Engine") }.each do |engine|
  FactoryGirl.definition_file_paths << File.join(engine.root, 'spec', 'factories')
end

FactoryGirl.find_definitions