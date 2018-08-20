require 'rails/engine'
require 'money-rails'

module ManageIQ
  module Showback
    class Engine < ::Rails::Engine
      isolate_namespace(ManageIQ::Showback)

      def vmdb_plugin?
        true
      end

      def self.plugin_name
        _('Consumption')
      end
    end
  end
end
