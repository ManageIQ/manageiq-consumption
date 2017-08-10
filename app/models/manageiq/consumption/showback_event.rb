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

  include_concern 'CPU'
  include_concern 'MEM'


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

  def generate_data
    self.data = {}
    ManageIQ::Consumption::ShowbackUsageType.all.each do |measure_type|
      next unless resource_type.include?(measure_type.category)
      self.data[measure_type.measure] = {}
      measure_type.dimensions.each do |dim|
        self.data[measure_type.measure][dim] = 0
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

  def update_event
    generate_data unless self.data.present?
    @metrics = if  resource.methods.include?(:metrics) then metrics_time_range(end_time,start_time.end_of_month) else [] end
    self.data.each do |key,dimensions|
      dimensions.keys.each do |dim|
        self.data[key][dim] = self.send("#{key}_#{dim}", data[key][dim].to_d)
      end
    end
    if @metrics.count>0
      self.end_time = @metrics.last.timestamp
    end
    collect_tags
  end

  def collect_tags
    if !self.context.present?
      self.context = {"tag" => {}}
    else
      self.context["tag"] = {} unless self.context.has_key?("tag")
    end
    resource.tags.each do |tag|
      category = tag.classification.category
      self.context["tag"][category] = [] unless self.context["tag"].has_key?(category)
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
        :state    => "OPEN")
  end

  #Get the parent of a respurce, we need ancestry here
  def get_parent(res, look)
    nil unless !res.methods.include?(look.tableize.singularize.to_sym)
    begin
      res.send(look.tableize.singularize)
    rescue
      nil
    end
  end

  HARDWARE_RESOURCE = %w(Vm Host EmsCluster ExtManagementSystem ).freeze
  CONTAINER_RESOURCE = %w(Container ContainerNode ContainerProject ExtManagementSystem).freeze

  def assign_resource
    find_pool(resource)&.add_event(self)
    resource_type = nil
    resource_type = resource.type.split("::")[-1] unless resource.type.nil?
    hierarchy = case
                  when HARDWARE_RESOURCE.include?(resource_type) then HARDWARE_RESOURCE
                  when CONTAINER_RESOURCE.include?(resource_type) then CONTAINER_RESOURCE
                  else []
                end
    hierarchy.each do |hw_res|
      next if resource.type.ends_with?(hw_res)
      parent_resource = get_parent(resource, hw_res)
      next if parent_resource.nil?
      find_pool(parent_resource)&.add_event(self)
    end
  end

  def assign_by_tag
    context["tag"].each do |category, array_children|
      t = Tag.find_by_classification_name(category)
      find_pool(t)&.add_event(self)
      array_children.each do |child_category|
        tag_child = t.classification.children.detect{|c| c.name == child_category}
        find_pool(tag_child.tag)&.add_event(self)
      end
    end
  end
end
