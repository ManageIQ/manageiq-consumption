class ManageIQ::Consumption::ShowbackPricePlan < ApplicationRecord
  self.table_name = 'showback_price_plans'
  has_many :showback_rates, :dependent => :destroy, :inverse_of => :showback_price_plan
  belongs_to :resource, :polymorphic => true

  validates :name, :presence => true
  validates :description, :presence => true
  validates :resource, :presence => true


  def calculate_cost(event)
    # Accumulator
    tc = 0
    # For each rate in the price_plan, try to find a measure, and if that exists, add rate
    # Get all rates for the price plan
    # Group them in category + dimension
    rates_hash = Hash.new { |h, k| h[k] = Array.new } # Create an array for each new value
    showback_rates.find_each do |x|
      rates_hash[x.name].push(x)
    end
    # For each group, select the one applying
    rates_hash.each do |_, xvalue|
      xvalue.each do |rate|
        # delete one hash from the other, so if it is empty
        result_hash = rate.screener
        result_hash.extract!(event.context || Hash.new())
        next unless result_hash == {}
        # TODO Find the tier (can be more than one)
        # Calculate the measure applicable to each tier
        measure = event.get_measure(rate.category, rate.dimension)
        tc += rate.rate(measure, event) unless measure.nil?
      end
    end
    tc
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

  private

  def self.seed_file_name
    @seed_file_name ||= Pathname.new(Gem.loaded_specs['manageiq-consumption'].full_gem_path).join("db", "fixtures", "#{table_name}.yml")
  end

  def self.seed_data
    File.exist?(seed_file_name) ? YAML.load_file(seed_file_name) : []
  end
end