class ManageIQ::Consumption::DataRollup < ApplicationRecord
  belongs_to :resource, :polymorphic => true

  has_many :showback_data_views,
           :dependent   => :destroy,
           :inverse_of  => :data_rollup,
           :foreign_key => :showback_data_rollup_id
  has_many :showback_envelopes,
           :through    => :showback_data_views,
           :inverse_of => :data_rollups

  validates :start_time, :end_time, :resource, :presence => true
  validate :start_time_before_end_time
  validates :resource, :presence => true

  serialize :data, JSON # Implement data column as a JSON
  default_value_for :data, {}

  serialize :context, JSON
  default_value_for :context, {}

  after_create :generate_data

  extend ActiveSupport::Concern

  Dir.glob(Pathname.new(File.dirname(__dir__)).join("consumption/data_rollup/*")).each { |lib| include_concern lib.split("consumption/data_rollup/")[1].split(".rb")[0].upcase }

  self.table_name = 'showback_data_rollups'

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

  def clean_data
    self.data = {}
  end

  def generate_data(data_units = ManageIQ::Consumption::ConsumptionManager.load_column_units)
    clean_data
    ManageIQ::Consumption::InputMeasure.all.each do |group_type|
      next unless resource_type.include?(group_type.entity)
      data[group_type.group] = {}
      group_type.fields.each do |dim|
        data[group_type.group][dim] = [0, data_units[dim.to_sym] || ""] unless group_type.group == "FLAVOR"
      end
    end
  end

  def self.data_rollups_between_month(start_of_month, end_of_month)
    ManageIQ::Consumption::DataRollup.where("start_time >= ? AND end_time <= ?",
                                            DateTime.now.utc.beginning_of_month.change(:month => start_of_month),
                                            DateTime.now.utc.end_of_month.change(:month => end_of_month))
  end

  def self.data_rollups_actual_month
    ManageIQ::Consumption::DataRollup.where("start_time >= ? AND end_time <= ?",
                                            DateTime.now.utc.beginning_of_month,
                                            DateTime.now.utc.end_of_month)
  end

  def self.data_rollups_past_month
    ManageIQ::Consumption::DataRollup.where("start_time >= ? AND end_time <= ?",
                                            DateTime.now.utc.beginning_of_month - 1.month,
                                            DateTime.now.utc.end_of_month - 1.month)
  end

  def get_group(entity, field)
    data[entity][field] if data && data[entity]
  end

  def get_group_unit(entity, field)
    get_group(entity, field).last
  end

  def get_group_value(entity, field)
    get_group(entity, field).first
  end

  def last_flavor
    data["FLAVOR"][data["FLAVOR"].keys.max]
  end

  def get_key_flavor(key)
    data["FLAVOR"][data["FLAVOR"].keys.max][key]
  end

  def update_data_rollup(data_units = ManageIQ::Consumption::ConsumptionManager.load_column_units)
    generate_data(data_units) unless data.present?
    @metrics = resource.methods.include?(:metrics) ? metrics_time_range(end_time, start_time.end_of_month) : []
    data.each do |key, fields|
      fields.keys.each do |dim|
        data[key][dim] = [generate_metric(key, dim), data_units[dim.to_sym] || ""]
      end
    end
    if @metrics.count.positive?
      self.end_time = @metrics.last.timestamp
    end
    collect_tags
    update_data_views
  end

  def generate_metric(key, dim)
    key == "FLAVOR" ? send("#{key}_#{dim}") : send("#{key}_#{dim}", get_group_value(key, dim).to_d)
  end

  def collect_tags
    if !self.context.present?
      self.context = {"tag" => {}}
    else
      self.context["tag"] = {} unless self.context.key?("tag")
    end
    resource.tagged_with(:ns => '/managed').each do |tag|
      entity = tag.classification.category
      self.context["tag"][entity] = [] unless self.context["tag"].key?(entity)
      self.context["tag"][entity] << tag.classification.name unless self.context["tag"][entity].include?(tag.classification.name)
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
  def data_rollup_days
    time_span / (24 * 60 * 60)
  end

  def time_span
    (end_time - start_time).round.to_i
  end

  def month_duration
    (end_time.end_of_month - start_time.beginning_of_month).round.to_i
  end

  # Find a envelope
  def find_envelope(res)
    ManageIQ::Consumption::ShowbackEnvelope.find_by(
      :resource => res,
      :state    => "OPEN"
    )
  end

  def assign_resource
    one_resource = resource
    # While I have resource loop looking for the parent find the pool asssociate and add the event
    until one_resource.nil?
      find_envelope(one_resource)&.add_data_rollup(self)
      one_resource = ManageIQ::Consumption::UtilsHelper.get_parent(one_resource)
    end
  end

  def assign_by_tag
    return unless context.key?("tag")
    context["tag"].each do |entity, array_children|
      t = Tag.find_by_classification_name(entity)
      find_envelope(t)&.add_data_rollup(self)
      array_children.each do |child_entity|
        tag_child = t.classification.children.detect { |c| c.name == child_entity }
        find_envelope(tag_child.tag)&.add_data_rollup(self)
      end
    end
  end

  def update_data_views
    ManageIQ::Consumption::ShowbackDataView.where(:data_rollup => self).each do |data_view|
      if data_view.open?
        data_view.update_data_snapshot
      end
    end
  end
end
