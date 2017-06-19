class ManageIQ::Consumption::ShowbackPricePlan < ApplicationRecord
  has_many :showback_rates, :dependent => :destroy, :inverse_of => :showback_price_plan
  belongs_to :resource, :polymorphic => true
  validates :name, :presence => true
  validates :description, :presence => true
  validates :resource, :presence => true

  self.table_name = "showback_price_plans"
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