# coding: utf-8

$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require 'manageiq/consumption/version'

Gem::Specification.new do |spec|
  spec.name          = "manageiq-consumption"
  spec.version       = ManageIQ::Consumption::VERSION
  spec.authors       = ["ManageIQ Developers"]

  spec.summary       = "ManageIQ Consumption"
  spec.description   = "ManageIQ Consumption"
  spec.homepage      = "https://github.com/miq-consumption/manageiq-consumption"
  spec.license       = "Apache-2.0"

  spec.files = Dir["{app,lib,spec}/**/*", "LICENSE.txt", "Rakefile", "README.md"]


  spec.add_dependency "money-rails", "~>1"

  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "codeclimate-test-reporter", "~> 1.0.0"
end
