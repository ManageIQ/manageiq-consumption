#
# Helper for data converters
#
# Allows the user to find interact with JSON and compare thems
#
#

module ManageIQ::Consumption
  module DataUtilsHelper
    def self.is_included_in?(context, test)
      # Validating that one JSON is completely included in the other
      # Only to be called with JSON!
      return false if test.nil? || context.nil?
      result = true
      test = {} if test.empty?
      HashDiff.diff(context, test).each do |x|
        result = false if (x[0] == '+' || x[0] == '~')
      end
      return result
    end
  end
end