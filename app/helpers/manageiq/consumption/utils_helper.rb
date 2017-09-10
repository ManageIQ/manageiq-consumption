module ManageIQ::Consumption
  module UtilsHelper
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

    #
    # Function for get the parent of a resource in MiQ
    #
    def self.get_parent(resource)
      parent_type = self.get_type_hierarchy_next(resource)
      #Check if the class has the method of the type of resource of the parent
      nil unless !resource.methods.include?(parent_type.tableize.singularize.to_sym)
      begin
        # I get the resource or returns nil
        resource.send(parent_type.tableize.singularize)
      rescue
        nil
      end
    end

    HARDWARE_RESOURCE = %w(Vm Host EmsCluster ExtManagementSystem Provider MiqEnterprise).freeze
    CONTAINER_RESOURCE = %w(Container ContainerNode ContainerReplicator ContainerProject ExtManagementSystem Provider MiqEnterprise).freeze

    #
    #  MiQ need to be implement ancestry for all kind of resources so we make our function to get the type of the parent
    #
    def self.get_type_hierarchy_next(resource)
      resource_type = resource.type.split("::")[-1] unless resource.type.nil?
      # I get the next type of resource parent
      case
      when HARDWARE_RESOURCE.include?(resource_type) then HARDWARE_RESOURCE[HARDWARE_RESOURCE.index(resource_type)+1] || ""
      when CONTAINER_RESOURCE.include?(resource_type) then CONTAINER_RESOURCE[CONTAINER_RESOURCE.index(resource_type)+1] || ""
      else ""
      end
    end
  end
end
