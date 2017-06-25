require 'spec_helper'
require 'money-rails/test_helpers'

RSpec.describe ManageIQ::Consumption::ShowbackPool, :type => :model do
  let(:pool) { FactoryGirl.build(:showback_pool) }
  let(:event) { FactoryGirl.build(:showback_event) }
  
  describe '#basic lifecycle' do
    it 'has a valid factory' do
      pool.valid?
      expect(pool).to be_valid
    end

    it 'is not valid without an association to a parent element' do
      pool.resource = nil
      pool.valid?
      expect(pool.errors.details[:resource]). to include(:error => :blank)
    end

    it 'is not valid without a name' do
      pool.name = nil
      pool.valid?
      expect(pool.errors.details[:name]). to include(:error => :blank)
    end

    it 'is not valid without a description' do
      pool.description = nil
      pool.valid?
      expect(pool.errors.details[:description]). to include(:error => :blank)
    end

    it 'deletes costs associated when deleting the pool' do
      FactoryGirl.create(:showback_charge, :showback_pool => pool)
      FactoryGirl.create(:showback_charge, :showback_pool => pool)
      expect(pool.showback_charges.count).to be(2)
      expect { pool.destroy }.to change(ManageIQ::Consumption::ShowbackCharge, :count).from(2).to(0)
    end

    it 'deletes costs associated when deleting the event' do
      FactoryGirl.create(:showback_charge, :showback_pool => pool)
      FactoryGirl.create(:showback_charge, :showback_pool => pool)
      expect(pool.showback_charges.count).to be(2)
      event = pool.showback_charges.first.showback_event
      expect { event.destroy }.to change(ManageIQ::Consumption::ShowbackCharge, :count).from(2).to(1)
    end

    it 'it can  be on states open, processing, close' do
      pool.state = "ERROR"
      expect(pool).not_to be_valid
      expect(pool.errors[:state]).to include "is not included in the list"
    end

    it 'it can not be different of states open, processing, close' do
      pool.state = "CLOSE"
      expect(pool).to be_valid
    end

    context ".control lifecycle state" do
      before(:each) do
        @pool_lifecycle = FactoryGirl.create(:showback_pool)
      end

      it 'it can transition from open to processing' do
        @pool_lifecycle.state = "PROCESSING"
        expect { @pool_lifecycle.save }.not_to raise_error
      end

      it 'a new pool is created automatically when transitioning from open to processing if not exists' do
        @pool_lifecycle.state = "PROCESSING"
        @pool_lifecycle.save
        expect(described_class.count).to eq(1)
      end

      it 'it can not transition from open to closed' do
        @pool_lifecycle.state = "CLOSE"
        expect { @pool_lifecycle.save }.to raise_error(RuntimeError, "Pool can't change its state to CLOSE from OPEN")
      end

      it 'it can not transition from processing to open' do
        @pool_lifecycle = FactoryGirl.create(:showback_pool_processing)
        @pool_lifecycle.state = "OPEN"
        expect { @pool_lifecycle.save }.to raise_error(RuntimeError, "Pool can't change its state to OPEN from PROCESSING")
      end

      it 'it can transition from processing to closed' do
        @pool_lifecycle = FactoryGirl.create(:showback_pool_processing)
        @pool_lifecycle.state = "CLOSE"
        expect { @pool_lifecycle.save }.not_to raise_error
      end

      it 'it can not transition from closed to open or processing' do
        @pool_lifecycle = FactoryGirl.create(:showback_pool_close)
        @pool_lifecycle.state = "OPEN"
        expect { @pool_lifecycle.save }.to raise_error(RuntimeError, "Pool can't change its state when it's CLOSE")
        @pool_lifecycle = FactoryGirl.create(:showback_pool_close)
        @pool_lifecycle.state = "PROCESSING"
        expect { @pool_lifecycle.save }.to raise_error(RuntimeError, "Pool can't change its state when it's CLOSE")
      end
    end

    pending 'it can not exists 2 pools opened from one resource'
  end

  describe "Methods events" do
    it 'Add event to a Pool' do
      count = pool.showback_events.count
      pool.add_event(event)
      expect(pool.showback_events.count).to eq(count + 1)
      expect(pool.showback_events).to include(event)
    end

    it 'Throw error in Add event to a Pool if duplicate' do
      pool.add_event(event)
      pool.add_event(event)
      expect(pool.errors.details[:showback_events]). to include(:error => "duplicate")
    end

    it 'Throw error in Add event is not type' do
      obj = FactoryGirl.create(:vm)
      pool.add_event(obj)
      expect(pool.errors.details[:showback_events]). to include(:error => "Error Type #{obj.type} is not ManageIQ::Consumption::ShowbackEvent")
    end

    it 'Remove event to a Pool' do
      pool.add_event(event)
      count = pool.showback_events.count
      pool.remove_event(event)
      expect(pool.showback_events.count).to eq(count - 1)
      expect(pool.showback_events).not_to include(event)
    end

    it 'Throw error in Remove event to a Pool if not found' do
      pool.add_event(event)
      pool.remove_event(event)
      pool.remove_event(event)
      expect(pool.errors.details[:showback_events]). to include(:error => "not found")
    end

    it 'Throw error in Remove event is not type' do
      obj = FactoryGirl.create(:vm)
      pool.remove_event(obj)
      expect(pool.errors.details[:showback_events]). to include(:error => "Error Type #{obj.type} is not ManageIQ::Consumption::ShowbackEvent")
    end
  end

  describe "methods charge" do
=begin
    it 'Add charge of a charge' do
      charge = FactoryGirl.create(:showback_charge)
      pool.add_charge(charge,2, 3)
      expect(charge.fixed_rate). to eq(Money.new(2))
      expect(charge.variable_rate). to eq(Money.new(3))
    end

    it 'Add charge of a event' do
      event  = FactoryGirl.create(:showback_event)
      charge = FactoryGirl.create(:showback_charge, :showback_event => event)
    end
=end
    it 'get_charge' do
      charge = FactoryGirl.create(:showback_charge, :showback_pool => pool, :cost => Money.new(10))
      expect(pool.get_charge(charge)).to eq(Money.new(10))
    end

    it 'get_charge with nil' do
      expect(pool.get_charge(nil)).to eq([nil, nil])
    end

    it 'calculate_charge with an error' do
      charge = FactoryGirl.create(:showback_charge, :showback_pool => pool, :cost => 10)
      pool.calculate_charge(charge)
      expect(charge.errors.details[:showback_price_plan]). to include(:error => "ShowbackPricePlan not found")
      expect(pool.calculate_charge(charge)). to be_nil
    end

    it 'calculate_charge fail with no charge' do
      pool.calculate_charge(nil)
      expect(pool.errors.details[:showback_charges]). to include(:error => "not found")
      expect(pool.calculate_charge(nil)). to be_nil
    end

    it 'Frind a price plan' do
      ManageIQ::Consumption::ShowbackPricePlan.seed
      expect(pool.find_price_plan).to eq(ManageIQ::Consumption::ShowbackPricePlan.first)
    end

    pending "Calculate charge"
    pending "Add charge"
    pending "Update charge"
    pending "nullify_charge"
    pending "sum_of_charges"
  end

  describe '#state:open' do
    it 'new events can be associated to the pool' do
      pool.save
      event.save
      expect { pool.showback_events << event }.to change(pool.showback_events, :count).by(1)
      expect(pool.showback_events.last).to eq(event)
    end
    it 'events can be associated to costs' do
      pool.save
      event.save
      expect { pool.showback_events << event }.to change(pool.showback_charges, :count).by(1)
      charge = pool.showback_charges.last
      expect(charge.showback_event).to eq(event)
      expect { charge.cost = Money.new(3) }.to change(charge, :cost).from(0).to(Money.new(3))
    end

    it 'monetized cost' do
      expect(ManageIQ::Consumption::ShowbackCharge).to monetize(:cost)
    end

    pending 'charges can be updated for an event'
    pending 'charges can be updated for all events in the pool'
    pending 'charges can be deleted for an event'
    pending 'charges can be deleted for all events in the pool'
    pending 'is possible to return charges for an event'
    pending 'is possible to return charges for all events'
    pending 'sum of charges can be calculated for the pool'
    pending 'sum of charges can be calculated for an event type'
  end

  describe '#state:processing' do
    pending 'new events are associated to a new or open pool'
    pending 'new events can not be associated to the pool'
    pending 'charges can be deleted for an event'
    pending 'charges can be deleted for all events in the pool'
    pending 'charges can be updated for an event'
    pending 'charges can be updated for all events in the pool'
    pending 'is possible to return charges for an event'
    pending 'is possible to return charges for all events'
    pending 'sum of charges can be calculated for the pool'
    pending 'sum of charges can be calculated for an event type'
  end

  describe '#state:closed' do
    pending 'new events can not be associated to the pool'
    pending 'new events are associated to a new or existing open pool'
    pending 'charges can not be deleted for an event'
    pending 'charges can not be deleted for all events in the pool'
    pending 'charges can not be updated for an event'
    pending 'charges can not be updated for all events in the pool'
    pending 'is possible to return charges for an event'
    pending 'is possible to return charges for all events'
    pending 'sum of charges can be calculated for the pool'
    pending 'sum of charges can be calculated for an event type'
  end
end