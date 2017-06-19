require 'rails/engine'
require 'money-rails'

module ManageIQ
  module Consumption
    class Engine < ::Rails::Engine
      isolate_namespace ManageIQ::Consumption

      initializer "model_core.factories", :after => "factory_girl.set_factory_paths" do
        FactoryGirl.definition_file_paths << File.expand_path('../../../spec/factories', __dir__) if defined?(FactoryGirl)
      end

      def vmdb_plugin?
        true
      end
    end
  end
end