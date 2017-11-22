module ManageIQ::Showback
  class PricePlan < ApplicationRecord
    self.table_name = 'showback_price_plans'
    has_many :rates,
             :dependent   => :destroy,
             :inverse_of  => :price_plan,
             :foreign_key => :showback_price_plan_id

    belongs_to :resource, :polymorphic => true

    validates :name, :presence => true
    validates :description, :presence => true
    validates :resource, :presence => true

    ###################################################################
    # Calculate the total cost of an event
    # Called with an event
    # Returns the total accumulated costs for all rates that apply
    ###################################################################
    def calculate_total_cost(data_rollup, cycle_duration = nil)
      total = 0
      calculate_list_of_costs(data_rollup, cycle_duration).each do |x|
        total += x[0]
      end
      total
    end

    def calculate_list_of_costs(data_rollup, cycle_duration = nil)
      cycle_duration ||= data_rollup.month_duration
      resource_type = data_rollup.resource&.type || data_rollup.resource_type
      # Accumulator
      tc = []
      # For each group type in InputMeasure, I need to find the rates applying to the different fields
      # If there is a rate associated to it, we call it with a group (that can be 0)
      ManageIQ::Showback::InputMeasure.where(:entity => resource_type).each do |usage|
        usage.fields.each do |dim|
          price_plan_rates = rates.where(:entity => usage.entity, :group => usage.group, :field => dim)
          price_plan_rates.each do |r|
            next unless ManageIQ::Showback::UtilsHelper.included_in?(data_rollup.context, r.screener)
            tc << [r.rate(data_rollup, cycle_duration), r]
          end
        end
      end
      tc
    end

    # Calculate the list of costs using input data instead of an event
    def calculate_list_of_costs_input(resource_type:,
                                      data:,
                                      context: nil,
                                      start_time: nil,
                                      end_time: nil,
                                      cycle_duration: nil)
      data_rollup = ManageIQ::Showback::DataRollup.new
      data_rollup.resource_type = resource_type
      data_rollup.data = data
      data_rollup.context = context || {}
      data_rollup.start_time = start_time || Time.current.beginning_of_month
      data_rollup.end_time = end_time || Time.current.end_of_month
      calculate_list_of_costs(data_rollup, cycle_duration)
    end

    #
    # Seeding one global price plan in the system that will be used as a fallback
    #
    def self.seed
      seed_data.each do |plan_attributes|
        plan_attributes_name = plan_attributes[:name]
        plan_attributes_description = plan_attributes[:description]
        plan_attributes_resource = plan_attributes[:resource_type].constantize.send(:find_by, :name => plan_attributes[:resource_name])

        next if ManageIQ::Showback::PricePlan.find_by(:name => plan_attributes_name, :resource => plan_attributes_resource)
        log_attrs = plan_attributes.slice(:name, :description, :resource_name, :resource_type)
        _log.info("Creating consumption price plan with parameters #{log_attrs.inspect}")
        _log.info("Creating #{plan_attributes_name} consumption price plan...")
        price_plan_new = create(:name => plan_attributes_name, :description => plan_attributes_description, :resource => plan_attributes_resource)
        price_plan_new.save
        _log.info("Creating #{plan_attributes_name} consumption price plan... Complete")
      end
    end

    def self.seed_file_name
      @seed_file_name ||= Pathname.new(Gem.loaded_specs['manageiq-consumption'].full_gem_path).join("db", "fixtures", "price_plans.yml")
    end

    def self.seed_data
      File.exist?(seed_file_name) ? YAML.load_file(seed_file_name) : []
    end
  end
end
