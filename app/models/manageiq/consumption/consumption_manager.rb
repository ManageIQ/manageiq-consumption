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
    generate_new_month unless Time.now.utc.strftime("%d").to_i != 1
    ManageIQ::Consumption::ShowbackEvent.events_actual_month.each do |event|
      event.update_event
      event.save
    end
  end

  def self.init_month
    DateTime.now.utc.beginning_of_month
  end

  def self.generate_new_month
    events = ManageIQ::Consumption::ShowbackEvent.events_past_month
    events.each do |ev|
      next unless !ManageIQ::Consumption::ShowbackEvent.where(["start_time >= ?",self.init_month]).exists?({:resource=> ev.resource})
      generate_event_resource(ev.resource, DateTime.now.utc.beginning_of_month)
    end
    events
  end

  RESOURCES_TYPES = %w(Vm Container Service).freeze

  def self.generate_events
    RESOURCES_TYPES.each do |resource|
      resource.constantize.all.each do |one_resource|
        next unless !ManageIQ::Consumption::ShowbackEvent.where(["start_time >= ?",self.init_month]).exists?({:resource => one_resource})
        generate_event_resource(one_resource, DateTime.now.utc)
      end
    end
  end

  def self.generate_event_resource(resource, date)
    e = ManageIQ::Consumption::ShowbackEvent.new(
        {
            :resource   => resource,
            :start_time => date,
            :end_time   => date
        }
    )
    e.generate_data
    e.collect_tags
    e.assign_resource
    e.assign_by_tag
    e.save!
  end
end