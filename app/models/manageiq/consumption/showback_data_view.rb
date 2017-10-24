class ManageIQ::Consumption::ShowbackDataView < ApplicationRecord
  self.table_name = 'showback_data_views'

  monetize(:cost_subunits)

  default_value_for :cost, 0

  belongs_to :showback_data_rollup, :inverse_of => :showback_data_views
  belongs_to :showback_envelope,  :inverse_of => :showback_data_views

  validates :showback_envelope,  :presence => true, :allow_nil => false
  validates :showback_data_rollup, :presence => true, :allow_nil => false

  serialize :cost, JSON # Implement cost column as a JSON
  serialize :data_snapshot, JSON # Implement data_snapshot column as a JSON
  serialize :context_snapshot, JSON # Implement context_snapshot column as a JSON
  before_create :snapshot_event
  default_value_for :data_snapshot, {}
  default_value_for :context_snapshot, {}


  # Set the cost to 0
  #
  def clean_cost
    self.cost = 0
    save
  end

  # Check if the pool is in a Open State
  #
  # == Returns:
  # A boolean value with true if it's open
  #
  def open?
    showback_envelope.state == "OPEN"
  end

  # A stored data is created when you create a charge with a snapshoot of the event
  # Save the actual data of the event
  #
  # == Parameters:
  # t::
  #   A timestamp of the snapshot. This
  #   can be a timestamp or `Time.now.utc`.
  #
  def snapshot_event(t = Time.now.utc)
    data_snapshot[t] = showback_data_rollup.data unless data_snapshot != {}
    context_snapshot = showback_data_rollup.context
  end

  # This returns the data information at the start of the pool
  #
  # == Returns:
  # A json data of the snapshot at start
  #
  def data_snapshot_start
    data_snapshot[data_snapshot.keys.sort.first] || nil
  end

  # Get last snapshot of the stored data
  #
  # == Returns:
  # The data information in json format or nil if not exists
  #
  def data_snapshot_last
    data_snapshot[data_snapshot_last_key] || nil
  end

  # Get last timestamp of the snapshots
  #
  # == Returns:
  # A timestamp value of the last snapshot
  #
  def data_snapshot_last_key
    data_snapshot.keys.sort.last || nil
  end

  # This update the last snapshoot of the event
  def update_data_snapshot(t = Time.now.utc)
    data_snapshot.delete(data_snapshot_last_key) unless data_snapshot.keys.length == 1
    data_snapshot[t] = showback_data_rollup.data
    save
  end

  def get_group(entity, field)
    get_data_group(data_snapshot_start, entity, field)
  end

  def get_last_group(entity, field)
    get_data_group(data_snapshot_last, entity, field)
  end

  # This return the entity|field group at the start and end of the pool
  def get_pool_group(entity, field)
    [get_data_group(data_snapshot_start, entity, field),
     get_data_group(data_snapshot_last, entity, field)]
  end

  def calculate_cost(price_plan = nil)
    # Find the price plan, there should always be one as it is seeded(Enterprise)
    price_plan ||= showback_envelope.find_price_plan
    if price_plan.class == ManageIQ::Consumption::ShowbackPricePlan
      cost = price_plan.calculate_total_cost(showback_data_rollup)
      save
      cost
    else
      errors.add(:showback_price_plan, _('not found'))
      Money.new(0)
    end
  end

  private

  def get_data_group(data, entity, field)
    data[entity][field] || nil if data && data[entity]
  end
end
