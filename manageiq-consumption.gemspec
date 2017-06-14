# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'manageiq/consumption/version'

Gem::Specification.new do |spec|
  spec.name          = "manageiq-consumption"
  spec.version       = ManageIQ::Consumption::VERSION
  spec.authors       = ["ManageIQ Developers"]

  spec.summary       = "ManageIQ Consumption"
  spec.description   = "ManageIQ Consumption"
  spec.homepage      = "https://github.com/miq-consumption/manageiq-consumption"
  spec.license       = "Apache-2.0"

  spec.files = Dir["{app,lib}/**/*", "LICENSE.txt", "Rakefile", "README.md"]

  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "codeclimate-test-reporter", "~> 1.0.0"
end