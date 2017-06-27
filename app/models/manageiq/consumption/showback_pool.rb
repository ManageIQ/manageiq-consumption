class ManageIQ::Consumption::ShowbackPool < ApplicationRecord
  self.table_name = 'showback_pools'

  belongs_to :resource, :polymorphic => true

  before_save :check_pool_state, :if => :state_changed?

  has_many :showback_charges,
           :dependent  => :destroy,
           :inverse_of => :showback_pool
  has_many :showback_events,
           :through    => :showback_charges,
           :inverse_of => :showback_pools

  validates :name,                  :presence => true
  validates :description,           :presence => true
  validates :resource,              :presence => true
  validates :start_time, :end_time, :presence => true
  validates :state,                 :presence => true, :inclusion => { :in => %w(OPEN PROCESSING CLOSE) }

  # Test that end_time happens later than start_time.
  validate  :start_time_before_end_time

  def start_time_before_end_time
    errors.add(:start_time, _("Start time should be before end time")) unless end_time.to_i > start_time.to_i
  end

  def check_pool_state
    case state_was
      when "OPEN"  then raise _("Pool can't change its state to CLOSE from OPEN") unless state != "CLOSE"
      when "PROCESSING"
        raise _("Pool can't change its state to OPEN from PROCESSING") unless state != "OPEN"
        s_time = (self.start_time + 1.months).beginning_of_month
        if self.end_time != self.start_time.end_of_month
          s_time = self.end_time
        else
          s_time = (self.start_time + 1.month).beginning_of_month
        end
        e_time = s_time.end_of_month
        ManageIQ::Consumption::ShowbackPool.create(:name => self.name,
                              :description => self.description,
                              :resource    => self.resource,
                              :start_time  => s_time,
                              :end_time    => e_time,
                              :state       => "OPEN"
        ) unless ManageIQ::Consumption::ShowbackPool.exists?(:resource => self.resource, :start_time  => s_time)
      when "CLOSE" then raise _("Pool can't change its state when it's CLOSE")
    end
  end

  def add_event(event)
    if event.kind_of? ManageIQ::Consumption::ShowbackEvent
      # verify that the event is not already there
      if showback_events.include?(event)
        errors.add(:showback_events, 'duplicate')
      else
        charge = ManageIQ::Consumption::ShowbackCharge.new(:showback_event  => event, :showback_pool => self)
        charge.save
      end
    else
      errors.add(:showback_events, "Error Type #{event.type} is not ManageIQ::Consumption::ShowbackEvent")
    end
  end

  # Remove events from a pool, no error is thrown

  def remove_event(event)
    if event.kind_of? ManageIQ::Consumption::ShowbackEvent
      if showback_events.include?(event)
        showback_events.delete event
      else
        errors.add(:showback_events, "not found")
      end
    else
      errors.add(:showback_events, "Error Type #{event.type} is not ManageIQ::Consumption::ShowbackEvent")
    end
  end

  def get_charge(input)
    ch = find_charge(input)
    if ch.nil?
      Money.new(0)
    else
      ch.cost
    end
  end

  def update_charge(input, cost)
    ch = find_charge(input)
    unless ch.nil?
      ch.cost = Money.new(cost)
      ch
    end
  end

  def add_charge(input, cost)
    ch = find_charge(input)
    # updates an existing charge
    if ch
      ch.cost = Money.new(cost)
    elsif input.class == ManageIQ::Consumption::ShowbackEvent # Or create a new one
      ch = showback_charges.new(:showback_event => input,
                                :cost           => cost)
    else
      errors.add(:input, 'bad class')
      return
    end
    ch.save
    ch
  end

  def clear_charge(input)
    ch = find_charge(input)
    ch.cost = 0
    ch.save
  end

  def sum_of_charges
    a = Money.new(0)
    showback_charges.each do |x|
      a += x.cost if x.cost
    end
    a
  end

  def clean_all_charges
    showback_charges.each(&:clean_cost)
  end

  def calculate_charge(input)
    ch = find_charge(input)
    if ch.kind_of? ManageIQ::Consumption::ShowbackCharge
      ch.cost = ch.calculate_cost(find_price_plan) || Money.new(0)
      save
    elsif input.nil?
      self.errors.add(:showback_charge, 'not found')
      Money.new(0)
    else
      input.errors.add(:showback_charge, 'not found')
      Money.new(0)
    end
  end

  def calculate_all_charges
    # plan = find_price_plan
    showback_charges.each do |x|
      calculate_charge(x)
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

  protected

  def find_charge(input)
    if input.kind_of? ManageIQ::Consumption::ShowbackEvent
      showback_charges.find_by :showback_event => input, :showback_pool => self
    elsif (input.kind_of? ManageIQ::Consumption::ShowbackCharge) && (input.showback_pool == self)
      input
    else
      nil
    end
  end
end