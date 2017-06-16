if ENV['CI']
  require 'simplecov'
  SimpleCov.start
end

require 'manageiq-consumption'

Dir[Rails.root.join("spec/shared/**/*.rb")].each { |f| require f }