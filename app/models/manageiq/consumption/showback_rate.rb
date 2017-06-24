class ManageIQ::Consumption::ShowbackRate < ApplicationRecord
  belongs_to :showback_price_plan, :inverse_of => :showback_rates

  monetize :fixed_rate_subunits
  monetize :variable_rate_subunits

  validates :fixed_rate_subunits,    :allow_nil => true, :default => nil
  validates :variable_rate_subunits, :allow_nil => true, :default => nil
  validates :calculation,:presence => true
  validates :category,   :presence => true
  validates :dimension,  :presence => true
  validates :screener,   :presence => true, :allow_blank => true

  self.table_name = "showback_rates"

  def name
    "#{category}:#{dimension}"
  end

  def rate(value, event)
    # Find tier (use context)
    # Calculate value within tier
    # For each tier used, calculate costs
    send(calculation.downcase, value, event) if private_methods.include? calculation.tableize.singularize.to_sym
  end

  private

  def occurrence(_value, event)
    # Returns fixed_cost + variable_cost prorated on time
    # total_time = calculate_total_time(event)
    # [event.fixed_cost, variable_cost * (end_time - start_time) / total_time]
    [fixed_rate, variable_rate * event.time_span / event.month_duration]
  end

  def duration(value, event)
    # Returns fixed_cost + event_measure * variable_cost * (end_time - start_time) / total_time
    # total_time = calculate_total_time(event)
    # [event.fixed_cost, event_measure * (event.end_time - event.start_time) / total_time]
    [fixed_rate * event.time_span / event.month_duration, value * variable_rate * event.time_span / event.month_duration]
  end

  def quantity(value, event)
    # event.fixed_cost + variable_cost * event
    # [event.fixed_cost, event_measure * variable_cost]
    [fixed_rate * event.time_span / event.month_duration, value * variable_rate]
  end
end