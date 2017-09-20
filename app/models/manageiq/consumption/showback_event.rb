class ManageIQ::Consumption::ShowbackEvent < ApplicationRecord
  belongs_to :resource, :polymorphic => true

  has_many :showback_charges,
           :dependent  => :destroy,
           :inverse_of => :showback_event
  has_many :showback_pools,
           :through    => :showback_charges,
           :inverse_of => :showback_events

  validates :start_time, :end_time, :resource, :presence => true
  validate :start_time_before_end_time
  validates :resource, :presence => true

  serialize :data, JSON # Implement data column as a JSON
  default_value_for :data, {}

  serialize :context, JSON
  default_value_for :context, {}

  after_create :generate_data

  extend ActiveSupport::Concern

  Dir.glob(Pathname.new(File.dirname(__dir__)).join("consumption/showback_event/*")).each { |lib| include_concern lib.split("consumption/showback_event/")[1].split(".rb")[0].upcase }

  self.table_name = 'showback_events'

  def start_time_before_end_time
    errors.add(:start_time, "Start time should be before end time") unless end_time.to_i >= start_time.to_i
  end

  # return the parsing error message if not valid JSON; otherwise nil
  def validate_format
    data = JSON.decode(data) if data.class == Hash
    JSON.parse(data) && nil if data.present?
  rescue JSON::ParserError
    nil
  end

  def generate_data(data_units = ManageIQ::Consumption::ConsumptionManager.load_column_units)
    self.data = {}
    ManageIQ::Consumption::ShowbackUsageType.all.each do |measure_type|
      next unless resource_type.include?(measure_type.category)
      self.data[measure_type.measure] = {}
      measure_type.dimensions.each do |dim|
        self.data[measure_type.measure][dim] = [0,data_units[dim.to_sym] || "" ] unless measure_type.measure == "FLAVOR"
      end
    end
  end

  def self.events_between_month(start_of_month, end_of_month)
    ManageIQ::Consumption::ShowbackEvent.where("start_time >= ? AND end_time <= ?",
                                               DateTime.now.utc.beginning_of_month.change(:month => start_of_month),
                                               DateTime.now.utc.end_of_month.change(:month => end_of_month))
  end

  def self.events_actual_month
    ManageIQ::Consumption::ShowbackEvent.where("start_time >= ? AND end_time <= ?",
                                               DateTime.now.utc.beginning_of_month,
                                               DateTime.now.utc.end_of_month)
  end

  def self.events_past_month
    ManageIQ::Consumption::ShowbackEvent.where("start_time >= ? AND end_time <= ?",
                                               DateTime.now.utc.beginning_of_month - 1.month,
                                               DateTime.now.utc.end_of_month - 1.month)
  end

  def get_measure(category, dimension)
    data[category][dimension] if (data && data[category])
  end

  def get_measure_unit(category, dimension)
    get_measure(category, dimension).last
  end

  def get_measure_value(category, dimension)
    get_measure(category, dimension).first
  end


  def get_last_flavor
    data["FLAVOR"][data["FLAVOR"].keys.max]
  end

  def get_key_flavor(key)
    data["FLAVOR"][data["FLAVOR"].keys.max][key]
  end

  def update_event(data_units = ManageIQ::Consumption::ConsumptionManager.load_column_units)
    generate_data(data_units) unless self.data.present?
    @metrics = if  resource.methods.include?(:metrics) then metrics_time_range(end_time,start_time.end_of_month) else [] end
    self.data.each do |key,dimensions|
      dimensions.keys.each do |dim|
        self.data[key][dim] = [generate_metric(key,dim),  data_units[dim.to_sym] || ""]
      end
    end
    if @metrics.count.positive?
      self.end_time = @metrics.last.timestamp
    end
    collect_tags
    update_charges
  end

  def generate_metric(key, dim)
    key == "FLAVOR" ? self.send("#{key}_#{dim}") : self.send("#{key}_#{dim}", get_measure_value(key,dim).to_d)
  end

  def collect_tags
    if !self.context.present?
      self.context = {"tag" => {}}
    else
      self.context["tag"] = {} unless self.context.key?("tag")
    end
    resource.tagged_with(:ns => '/managed').each do |tag|
      next unless tag.classification
      category = tag.classification.category
      self.context["tag"][category] = [] unless self.context["tag"].key?(category)
      self.context["tag"][category] << tag.classification.name unless self.context["tag"][category].include?(tag.classification.name)
    end
  end

  #
  #  Get the metrics between two dates using metrics common for_time_range defined in CU MiQ
  #
  def metrics_time_range(start_time, end_time)
    resource.metrics.for_time_range(start_time, end_time)
  end

  #
  #  Return the event days passed between start_time - end_time
  #
  def event_days
    time_span / (24 * 60 * 60)
  end

  def time_span
    (end_time - start_time).round.to_i
  end

  def month_duration
    (end_time.end_of_month - start_time.beginning_of_month).round.to_i
  end

  #
  #  Assign to Pool
  #

  # Find a pool
  def find_pool(res)
    ManageIQ::Consumption::ShowbackPool.find_by(
      :resource => res,
      :state    => "OPEN"
    )
  end

  def assign_resource
    one_resource = resource
    # While I have resource loop looking for the parent find the pool asssociate and add the event
    until one_resource.nil?
      find_pool(one_resource)&.add_event(self)
      one_resource = ManageIQ::Consumption::UtilsHelper.get_parent(one_resource)
    end
  end

  def assign_by_tag
    context["tag"].each do |category, array_children|
      t = Tag.find_by_classification_name(category)
      find_pool(t)&.add_event(self)
      array_children.each do |child_category|
        tag_child = t.classification.children.detect { |c| c.name == child_category }
        find_pool(tag_child.tag)&.add_event(self)
      end
    end
  end

  def update_charges
    ManageIQ::Consumption::ShowbackCharge.where(:showback_event=>self).each do |charge|
      if charge.is_open?
        charge.update_stored_data
      end
    end
  end
end
