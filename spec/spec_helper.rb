if ENV['CI']
  require 'simplecov'
  SimpleCov.start
end

require 'manageiq-consumption'



Dir[ManageIQ::Consumption::Engine.root.join("spec/support/**/*.rb")].each { |f| require f }

