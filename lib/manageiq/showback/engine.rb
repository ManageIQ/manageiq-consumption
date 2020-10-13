require 'money-rails'

module ManageIQ
  module Showback
    class Engine < ::Rails::Engine
      isolate_namespace ManageIQ::Showback

      config.autoload_paths << root.join('lib').to_s

      def self.vmdb_plugin?
        true
      end

      def self.plugin_name
        _('Showback')
      end
    end
  end
end
