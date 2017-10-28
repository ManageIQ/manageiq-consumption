class ManageIQ::Consumption::Envelope < ApplicationRecord
  self.table_name = 'showback_envelopes'

  belongs_to :resource, :polymorphic => true

  monetize :accumulated_cost_subunits
  default_value_for :accumulated_cost, Money.new(0)

  before_save :check_envelope_state, :if => :state_changed?

  has_many :data_views,
           :dependent   => :destroy,
           :inverse_of  => :envelope,
           :foreign_key => :showback_envelope_id
  has_many :data_rollups,
           :through     => :data_views,
           :inverse_of  => :envelopes,
           :foreign_key => :showback_envelope_id

  validates :name,                  :presence => true
  validates :description,           :presence => true
  validates :resource,              :presence => true
  validates :start_time, :end_time, :presence => true
  validates :state,                 :presence => true, :inclusion => { :in => %w(OPEN PROCESSING CLOSED) }

  # Test that end_time happens later than start_time.
  validate  :start_time_before_end_time

  def start_time_before_end_time
    errors.add(:end_time, _('should happen after start_time')) unless end_time.to_i > start_time.to_i
  end

  def check_envelope_state
    case state_was
    when 'OPEN' then
      raise _("Envelope can't change state to CLOSED from OPEN") unless state != 'CLOSED'
      # s_time = (self.start_time + 1.months).beginning_of_month # This is never used
      s_time = end_time != start_time.end_of_month ? end_time : (start_time + 1.month).beginning_of_month
      e_time = s_time.end_of_month
      generate_envelope(s_time, e_time) unless ManageIQ::Consumption::Envelope.exists?(:resource => resource, :start_time => s_time)
    when 'PROCESSING' then raise _("Envelope can't change state to OPEN from PROCESSING") unless state != 'OPEN'
    when 'CLOSED' then raise _("Envelope can't change state when it's CLOSED")
    end
  end

  def add_data_rollup(data_rollup)
    if data_rollup.kind_of?(ManageIQ::Consumption::DataRollup)
      # verify that the event is not already there
      if data_rollups.include?(data_rollup)
        errors.add(:data_rollups, 'duplicate')
      else
        dataview = ManageIQ::Consumption::DataView.new(:data_rollup => data_rollup, :envelope => self)
        dataview.save
      end
    else
      errors.add(:data_rollups, "Error Type #{data_rollup.type} is not ManageIQ::Consumption::DataRollup")
    end
  end

  # Remove events from a envelope, no error is thrown

  def remove_data_rollup(data_rollup)
    if data_rollup.kind_of?(ManageIQ::Consumption::DataRollup)
      if data_rollups.include?(data_rollup)
        data_rollups.delete(data_rollup)
      else
        errors.add(:data_rollups, "not found")
      end
    else
      errors.add(:data_rollups, "Error Type #{data_rollup.type} is not ManageIQ::Consumption::DataRollup")
    end
  end

  def get_data_view(input)
    ch = find_data_view(input)
    if ch.nil?
      Money.new(0)
    else
      ch.cost
    end
  end

  def update_data_view(input, cost)
    ch = find_data_view(input)
    unless ch.nil?
      ch.cost = Money.new(cost)
      ch
    end
  end

  def add_data_view(input, cost)
    ch = find_data_view(input)
    # updates an existing dataviews
    if ch
      ch.cost = Money.new(cost)
    elsif input.class == ManageIQ::Consumption::DataRollup # Or create a new one
      ch = data_views.new(:data_rollup => input,
                          :cost        => cost)
    else
      errors.add(:input, 'bad class')
      return
    end
    ch.save
    ch
  end

  def clear_data_view(input)
    ch = find_data_view(input)
    ch.cost = 0
    ch.save
  end

  def sum_of_data_views
    a = Money.new(0)
    data_views.each do |x|
      a += x.cost if x.cost
    end
    a
  end

  def clean_all_data_views
    data_views.each(&:clean_cost)
  end

  def calculate_data_view(input)
    ch = find_data_view(input)
    if ch.kind_of?(ManageIQ::Consumption::DataView)
      ch.cost = ch.calculate_cost(find_price_plan) || Money.new(0)
      save
    elsif input.nil?
      errors.add(:data_view, 'not found')
      Money.new(0)
    else
      input.errors.add(:data_view, 'not found')
      Money.new(0)
    end
  end

  def calculate_all_data_views
    # plan = find_price_plan
    data_views.each do |x|
      calculate_data_view(x)
    end
  end

  def find_price_plan
    # TODO
    # For the demo: return one price plan, we will create the logic later
    # parent = resource
    # do
    # result = ManageIQ::Providers::Consumption::ConsumptionManager::ShowbackPricePlan.where(resource: parent)
    # parent = parent.parent if !result
    # while !result || !parent
    # result || ManageIQ::Providers::Consumption::ConsumptionManager::ShowbackPricePlan.where(resource = MiqEnterprise)
    ManageIQ::Consumption::ShowbackPricePlan.first
  end

  def find_data_view(input)
    if input.kind_of?(ManageIQ::Consumption::DataRollup)
      data_views.find_by(:data_rollup => input, :envelope => self)
    elsif input.kind_of?(ManageIQ::Consumption::DataView) && (input.envelope == self)
      input
    end
  end

  private

  def generate_envelope(s_time, e_time)
    envelope = ManageIQ::Consumption::Envelope.create(:name        => name,
                                                      :description => description,
                                                      :resource    => resource,
                                                      :start_time  => s_time,
                                                      :end_time    => e_time,
                                                      :state       => 'OPEN')
    data_views.each do |data_view|
      ManageIQ::Consumption::DataView.create(
        :stored_data   => {
          data_view.stored_data_last_key => data_view.stored_data_last
        },
        :data_rollup   => data_view.showback_event,
        :envelope      => envelope,
        :cost_subunits => data_view.cost_subunits,
        :cost_currency => data_view.cost_currency
      )
    end
  end
end
