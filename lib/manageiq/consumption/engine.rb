require 'rails/engine'
require 'money-rails'

module ManageIQ
  module Consumption
    class Engine < ::Rails::Engine
      isolate_namespace(ManageIQ::Consumption)

      def vmdb_plugin?
        true
      end
    end
  end
end
