require 'rails/engine'

module ManageIQ
  module Consumption
    class Engine < ::Rails::Engine
      isolate_namespace ManageIQ::Consumption

      config.autoload_paths << root.join("app/models")

      def vmdb_plugin?
        true
      end
    end
  end
end