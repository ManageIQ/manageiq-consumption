# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'manageiq/showback/version'

Gem::Specification.new do |spec|
  spec.name          = "manageiq-consumption"
  spec.version       = ManageIQ::Showback::VERSION
  spec.authors       = ["ManageIQ Authors"]

  spec.summary       = "Consumption plugin for ManageIQ."
  spec.description   = "Consumption plugin for ManageIQ."
  spec.homepage      = "https://github.com/ManageIQ/manageiq-consumption"
  spec.license       = "Apache-2.0"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "money-rails", "~> 1.9"
  spec.add_dependency "hashdiff", "~> 1.0"

  spec.add_development_dependency "manageiq-style"
  spec.add_development_dependency "simplecov", ">= 0.21.2"
end
