class ManageIQ::Consumption::ConsumptionManager
  def self.name
    "Consumption"
  end

  def self.ems_type
    @ems_type ||= "consumption_manager".freeze
  end

  def self.description
    @description ||= "Consumption Manager".freeze
  end

  def self.update_data_rollups
    data_units = load_column_units
    generate_new_month unless Time.now.utc.strftime("%d").to_i != 1
    ManageIQ::Consumption::DataRollup.data_rollups_actual_month.each do |event|
      event.update_data_rollup(data_units)
      event.save
    end
  end

  def self.init_month
    DateTime.now.utc.beginning_of_month
  end

  def self.generate_new_month
    data_rollups = ManageIQ::Consumption::DataRollup.data_rollups_past_month
    data_rollups.each do |dr|
      next if ManageIQ::Consumption::DataRollup.where(["start_time >= ?", init_month]).exists?(:resource=> dr.resource)
      generate_data_rollup_resource(dr.resource, DateTime.now.utc.beginning_of_month, load_column_units)
    end
    data_rollups
  end

  RESOURCES_TYPES = %w(Vm Container Service).freeze

  def self.generate_data_rollups
    RESOURCES_TYPES.each do |resource|
      resource.constantize.all.each do |one_resource|
        next if ManageIQ::Consumption::DataRollup.where(["start_time >= ?", init_month]).exists?(:resource => one_resource)
        generate_data_rollup_resource(one_resource, DateTime.now.utc, load_column_units)
      end
    end
  end

  def self.generate_data_rollup_resource(resource, date, data_units)
    data_rollup = ManageIQ::Consumption::DataRollup.new(
      :resource   => resource,
      :start_time => date,
      :end_time   => date
    )
    data_rollup.generate_data(data_units)
    data_rollup.collect_tags
    data_rollup.assign_resource
    data_rollup.assign_by_tag
    data_rollup.save!
  end

  def self.seed
    ManageIQ::Consumption::InputMeasure.seed
    ManageIQ::Consumption::ShowbackPricePlan.seed
  end

  def self.load_column_units
    File.exist?(seed_file_name) ? YAML.load_file(seed_file_name) : []
  end

  def self.seed_file_name
    @seed_file_name ||= Pathname.new(Gem.loaded_specs['manageiq-consumption'].full_gem_path).join("app/models/manageiq/consumption", "column_units.yml")
  end
  private_class_method :seed_file_name
end
