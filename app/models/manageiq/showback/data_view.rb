module ManageIQ::Showback
  class DataView < ApplicationRecord
    self.table_name = 'showback_data_views'

    monetize(:cost_subunits)

    default_value_for :cost, 0

    belongs_to :data_rollup, :inverse_of => :data_views, :foreign_key => :showback_data_rollup_id
    belongs_to :envelope,    :inverse_of => :data_views, :foreign_key => :showback_envelope_id

    validates :envelope,    :presence => true, :allow_nil => false
    validates :data_rollup, :presence => true, :allow_nil => false

    before_create :snapshot_data_rollup
    default_value_for :data_snapshot, {}
    default_value_for :context_snapshot, {}

    #
    # Set the cost to 0
    #
    def clean_cost
      self.cost = 0
      save
    end

    # Check if the envelope is in a Open State
    #
    # == Returns:
    # A boolean value with true if it's open
    #
    def open?
      envelope.state == "OPEN"
    end

    # A stored data is created when you create a dataview with a snapshoot of the event
    # Save the actual data of the event
    #
    # == Parameters:
    # t::
    #   A timestamp of the snapshot. This
    #   can be a timestamp or `Time.now.utc`.
    #
    def snapshot_data_rollup(t = Time.now.utc)
      data_snapshot[t] = data_rollup.data unless data_snapshot != {}
      self.context_snapshot = data_rollup.context
    end

    # This returns the data information at the start of the envelope
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
      data_snapshot[t] = data_rollup.data
      save
    end

    def get_group(entity, field)
      get_data_group(data_snapshot_start, entity, field)
    end

    def get_last_group(entity, field)
      get_data_group(data_snapshot_last, entity, field)
    end

    # This return the entity|field group at the start and end of the envelope
    def get_envelope_group(entity, field)
      [get_data_group(data_snapshot_start, entity, field),
       get_data_group(data_snapshot_last, entity, field)]
    end

    def calculate_cost(price_plan = nil)
      # Find the price plan, there should always be one as it is seeded(Enterprise)
      price_plan ||= envelope.find_price_plan
      if price_plan.class == ManageIQ::Showback::PricePlan
        cost = price_plan.calculate_total_cost(data_rollup)
        save
        cost
      else
        errors.add(:price_plan, _('not found'))
        Money.new(0)
      end
    end

    private

    def get_data_group(data, entity, field)
      data[entity][field] || nil if data && data[entity]
    end
  end
end
