class ManageIQ::Consumption::ShowbackPricePlan < ApplicationRecord
  self.table_name = 'showback_price_plans'
  has_many :showback_rates, :dependent => :destroy, :inverse_of => :showback_price_plan
  belongs_to :resource, :polymorphic => true

  validates :name, :presence => true
  validates :description, :presence => true
  validates :resource, :presence => true

  ###################################################################
  # Calculate the total cost of an event
  # Called with an event
  # Returns the total accumulated costs for all rates that apply
  ###################################################################
  def calculate_total_cost(event, cycle_duration = nil)
    total = 0
    calculate_list_of_costs(event, cycle_duration).each do |x|
      total += x[0]
    end
    total
  end

  def calculate_list_of_costs(event, cycle_duration = nil)
    cycle_duration ||= event.month_duration
    resource_type = event.resource&.type || event.resource_type
    # Accumulator
    tc = []
    # For each group type in ShowbackUsageType, I need to find the rates applying to the different fields
    # If there is a rate associated to it, we call it with a group (that can be 0)
    ManageIQ::Consumption::InputMeasure.where(:entity => resource_type).each do |usage|
      usage.fields.each do |dim|
        rates = showback_rates.where(:entity => usage.entity, :group => usage.group, :field => dim)
        rates.each do |r|
          next unless ManageIQ::Consumption::UtilsHelper.included_in?(event.context, r.screener)
          tc << [r.rate(event, cycle_duration), r]
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
    event = ManageIQ::Consumption::ShowbackDataRollup.new
    event.resource_type = resource_type
    event.data = data
    event.context = context || {}
    event.start_time = start_time || Time.current.beginning_of_month
    event.end_time = end_time || Time.current.end_of_month
    calculate_list_of_costs(event, cycle_duration)
  end

  #
  # Seeding one global price plan in the system that will be used as a fallback
  #
  def self.seed
    seed_data.each do |plan_attributes|
      plan_attributes_name = plan_attributes[:name]
      plan_attributes_description = plan_attributes[:description]
      plan_attributes_resource = plan_attributes[:resource_type].constantize.send(:find_by, :name => plan_attributes[:resource_name])

      next if ManageIQ::Consumption::ShowbackPricePlan.find_by(:name => plan_attributes_name, :resource => plan_attributes_resource)
      log_attrs = plan_attributes.slice(:name, :description, :resource_name, :resource_type)
      _log.info("Creating consumption price plan with parameters #{log_attrs.inspect}")
      _log.info("Creating #{plan_attributes_name} consumption price plan...")
      price_plan_new = create(:name => plan_attributes_name, :description => plan_attributes_description, :resource => plan_attributes_resource)
      price_plan_new.save
      _log.info("Creating #{plan_attributes_name} consumption price plan... Complete")
    end
  end

  def self.seed_file_name
    @seed_file_name ||= Pathname.new(Gem.loaded_specs['manageiq-consumption'].full_gem_path).join("db", "fixtures", "#{table_name}.yml")
  end

  def self.seed_data
    File.exist?(seed_file_name) ? YAML.load_file(seed_file_name) : []
  end
end
