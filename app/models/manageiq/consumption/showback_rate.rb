class ManageIQ::Consumption::ShowbackRate < ApplicationRecord
  self.table_name = 'showback_rates'
  belongs_to :showback_price_plan, :inverse_of => :showback_rates

  monetize :fixed_rate_subunits,    :with_model_currency => :currency
  monetize :variable_rate_subunits, :with_model_currency => :currency

  validates :calculation, :presence => true, :inclusion => { :in => %w(occurrence duration quantity) }
  validates :category,    :presence => true
  validates :dimension,   :presence => true

  serialize :screener, JSON # Implement data column as a JSON
  default_value_for :screener, { }

  def name
    "#{category}:#{dimension}"
  end

  def rate(value, event)
    # Find tier (use context)
    # Calculate value within tier
    # For each tier used, calculate costs
    rate_with_values(value || 0, event.time_span, event.month_duration) if private_methods.include? calculation.tableize.singularize.to_sym
  end

  def rate_with_values(value, time_span, cycle_duration)
    send(calculation.downcase, value || 0, time_span, cycle_duration) if private_methods.include? calculation.tableize.singularize.to_sym
  end

  private

  def occurrence(_value, time_span, month_duration)
    # Returns fixed_cost + variable_cost prorated on time
    # total_time = calculate_total_time(event)
    # [event.fixed_cost, variable_cost * (end_time - start_time) / total_time]
    fixed_rate + (variable_rate * time_span / month_duration)
  end

  def duration(value, time_span, month_duration)
    # Returns fixed_cost + event_measure * variable_cost * (end_time - start_time) / total_time
    # total_time = calculate_total_time(event)
    # [event.fixed_cost, event_measure * (event.end_time - event.start_time) / total_time]
    (fixed_rate * time_span / month_duration) + (value * variable_rate * time_span / month_duration)
  end

  def quantity(value, time_span, month_duration)
    # event.fixed_cost + variable_cost * event
    # [event.fixed_cost, event_measure * variable_cost]
    (fixed_rate * time_span / month_duration) + (value * variable_rate)
  end
end
