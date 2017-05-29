require "bundler/gem_tasks"
require "rspec/core/rake_task"
require 'rake'
require 'rake/testtask'

RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = "--options #{File.expand_path(".rspec_ci", __dir__)}" if ENV['CI']
end

Rake::TestTask.new do |t|
  t.test_files = FileList['test/ts_*.rb']
end

task :default do
  Rake::Task["spec"].invoke
  Rake::Task["test"].invoke
end
