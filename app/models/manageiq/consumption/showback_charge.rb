class ManageIQ::Consumption::ShowbackCharge < ApplicationRecord
  self.table_name = 'showback_charges'
  monetize :cost_subunits
  default_value_for :cost, 0

  belongs_to :showback_event, :inverse_of => :showback_charges
  belongs_to :showback_pool,  :inverse_of => :showback_charges

  validates :showback_pool,  :presence => true, :allow_nil => false
  validates :showback_event, :presence => true, :allow_nil => false

  serialize :cost, JSON # Implement cost column as a JSON
  serialize :stored_data, JSON # Implement stored_data column as a JSON
  before_create :stored_data_event
  default_value_for :stored_data, {}

  def clean_cost
    self.cost = 0
    save
  end

  def is_open?
    showback_pool.state == "OPEN"
  end
  #A stored data is created when you create a charge with a snapshoot of the event
  def stored_data_event(t = Time.now.utc)
    self.stored_data[t] = self.showback_event.data unless self.stored_data != {}
  end

  #This returns the data information at the start of the pool
  def stored_data_start
    self.stored_data[stored_data.keys.sort.first] || nil
  end


  #This returns the data information at the end of the pool
  def stored_data_last
    self.stored_data[stored_data_last_key] || nil
  end

  #This returns the last key of the stored data == the last timestamp of the event data snapshoot
  def stored_data_last_key
    self.stored_data.keys.sort.last || nil
  end

  #This update the last snapshoot of the event
  def update_stored_data(t = Time.now.utc)
    self.stored_data.delete(stored_data_last_key) unless self.stored_data.keys.length == 1
    self.stored_data[t] = showback_event.data
    save
  end

  def get_measure(category, dimension)
    get_data_measure(stored_data_start,category, dimension)
  end

  def get_last_measure(category, dimension)
    get_data_measure(stored_data_last,category, dimension)
  end

  #This return the category|dimension measure at the start and end of the pool
  def get_pool_measure(category, dimension)
    [get_data_measure(stored_data_start,category, dimension),
     get_data_measure(stored_data_last,category, dimension)]
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

  def get_data_measure(data,category, dimension)
    data[category][dimension] || nil if (data && data[category])
  end
end
