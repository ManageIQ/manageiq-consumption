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
  def calculate_total_cost(event)
    # Accumulator
    tc = Money.new(0)
    # For each measure type in ShowbackUsageType, I need to find the rates applying to the different dimensions
    # If there is a rate associated to it, we call it with a measure (that can be 0)

    ManageIQ::Consumption::ShowbackUsageType.all.each do |usage|
      usage.dimensions.each do |dim|
        rates = showback_rates.where(category: usage.category, dimension: "#{usage.measure}##{dim}")
        rates.each do |r|
          next unless ManageIQ::Consumption::DataUtilsHelper.is_included_in? event.context, r.screener
          measure = event.get_measure(r.category, usage.measure, dim)
          tc += r.rate(measure, event)
        end
      end
    end
    tc
  end

  def calculate_total_cost_with_values(event, start_time, end_time)

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
