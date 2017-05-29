require "bundler/gem_tasks"
require "rspec/core/rake_task"
require 'rake'
require 'rake/testtask'

begin
  require 'rspec/core/rake_task'

  APP_RAKEFILE = File.expand_path("../spec/manageiq/Rakefile", __FILE__)
  load 'rails/tasks/engine.rake'
rescue LoadError
end


namespace :spec do
  desc "Setup environment for specs"
  task :setup => 'app:test:consumption:setup'
end

desc "Run all consumption specs"
task :spec => 'app:test:consumption'

task :default do
  Rake::Task["spec"].invoke
end
