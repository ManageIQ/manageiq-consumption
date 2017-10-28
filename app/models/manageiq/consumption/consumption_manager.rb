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

  def self.update_events
    data_units = load_column_units
    generate_new_month unless Time.now.utc.strftime("%d").to_i != 1
    ManageIQ::Consumption::ShowbackDataRollup.events_actual_month.each do |event|
      event.update_event(data_units)
      event.save
    end
  end

  def self.init_month
    DateTime.now.utc.beginning_of_month
  end

  def self.generate_new_month
    events = ManageIQ::Consumption::ShowbackDataRollup.events_past_month
    events.each do |ev|
      next if ManageIQ::Consumption::ShowbackDataRollup.where(["start_time >= ?", init_month]).exists?(:resource=> ev.resource)
      generate_event_resource(ev.resource, DateTime.now.utc.beginning_of_month, load_column_units)
    end
    events
  end

  RESOURCES_TYPES = %w(Vm Container Service).freeze

  def self.generate_events
    RESOURCES_TYPES.each do |resource|
      resource.constantize.all.each do |one_resource|
        next if ManageIQ::Consumption::ShowbackDataRollup.where(["start_time >= ?", init_month]).exists?(:resource => one_resource)
        generate_event_resource(one_resource, DateTime.now.utc, load_column_units)
      end
    end
  end

  def self.generate_event_resource(resource, date, data_units)
    e = ManageIQ::Consumption::ShowbackDataRollup.new(
      :resource   => resource,
      :start_time => date,
      :end_time   => date
    )
    e.generate_data(data_units)
    e.collect_tags
    e.assign_resource
    e.assign_by_tag
    e.save!
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
