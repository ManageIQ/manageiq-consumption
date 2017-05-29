module ManageIQ
  module Consumption
    class ShowbackUsageType < Rails::Engine
      include ActiveModel::Validations
      validates :description, :category, :measure, :dimensions, :presence => true

      def name
        "#{category}::#{measure}"
      end
    end
  end
end