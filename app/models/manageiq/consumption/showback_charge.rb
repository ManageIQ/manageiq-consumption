class ManageIQ::Consumption::ShowbackCharge < ApplicationRecord
  self.table_name = 'showback_charges'

  monetize(:cost_subunits)

  default_value_for :cost, 0

  belongs_to :showback_event, :inverse_of => :showback_charges
  belongs_to :showback_pool,  :inverse_of => :showback_charges

  validates :showback_pool,  :presence => true, :allow_nil => false
  validates :showback_event, :presence => true, :allow_nil => false

  serialize :cost, JSON # Implement cost column as a JSON
  serialize :stored_data, JSON # Implement stored_data column as a JSON
  before_create :stored_data_event
  default_value_for :stored_data, {}

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
    showback_pool.state == "OPEN"
  end

  # A stored data is created when you create a charge with a snapshoot of the event
  # Save the actual data of the event
  #
  # == Parameters:
  # t::
  #   A timestamp of the snapshot. This
  #   can be a timestamp or `Time.now.utc`.
  #
  def stored_data_event(t = Time.now.utc)
    stored_data[t] = showback_event.data unless stored_data != {}
  end

  # This returns the data information at the start of the pool
  #
  # == Returns:
  # A json data of the snapshot at start
  #
  def stored_data_start
    stored_data[stored_data.keys.sort.first] || nil
  end

  # Get last snapshot of the stored data
  #
  # == Returns:
  # The data information in json format or nil if not exists
  #
  def stored_data_last
    stored_data[stored_data_last_key] || nil
  end

  # Get last timestamp of the snapshots
  #
  # == Returns:
  # A timestamp value of the last snapshot
  #
  def stored_data_last_key
    stored_data.keys.sort.last || nil
  end

  # This update the last snapshoot of the event
  def update_stored_data(t = Time.now.utc)
    stored_data.delete(stored_data_last_key) unless stored_data.keys.length == 1
    stored_data[t] = showback_event.data
    save
  end

  def get_measure(category, dimension)
    get_data_measure(stored_data_start, category, dimension)
  end

  def get_last_measure(category, dimension)
    get_data_measure(stored_data_last, category, dimension)
  end

  # This return the category|dimension measure at the start and end of the pool
  def get_pool_measure(category, dimension)
    [get_data_measure(stored_data_start, category, dimension),
     get_data_measure(stored_data_last, category, dimension)]
  end

  def calculate_cost(price_plan = nil)
    # Find the price plan, there should always be one as it is seeded(Enterprise)
    price_plan ||= showback_pool.find_price_plan
    if price_plan.class == ManageIQ::Consumption::ShowbackPricePlan
      cost = price_plan.calculate_total_cost(showback_event)
      save
      cost
    else
      errors.add(:showback_price_plan, _('not found'))
      Money.new(0)
    end
  end

  private

  def get_data_measure(data, category, dimension)
    data[category][dimension] || nil if data && data[category]
  end
end
