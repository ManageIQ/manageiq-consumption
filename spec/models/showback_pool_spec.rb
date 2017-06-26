require 'spec_helper'
require 'money-rails/test_helpers'

RSpec.describe ManageIQ::Consumption::ShowbackPool, :type => :model do
  let(:pool)    { FactoryGirl.build(:showback_pool) }
  let(:event)   { FactoryGirl.build(:showback_event, :with_vm_data, :full_month) }
  let(:event2)  { FactoryGirl.build(:showback_event, :with_vm_data, :full_month) }
  let(:enterprise_plan) { FactoryGirl.create(:showback_price_plan) }

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
      2.times do
        FactoryGirl.create(:showback_charge, :showback_pool => pool)
      end
      expect(pool.showback_charges.count).to be(2)
      expect { pool.destroy }.to change(ManageIQ::Consumption::ShowbackCharge, :count).from(2).to(0)
    end

    it 'deletes costs associated when deleting the event' do
      2.times do
        FactoryGirl.create(:showback_charge, :showback_pool => pool)
      end
      expect(pool.showback_charges.count).to be(2)
      event = pool.showback_charges.first.showback_event
      expect { event.destroy }.to change(ManageIQ::Consumption::ShowbackCharge, :count).from(2).to(1)
    end

    it 'it can  be on states open, processing, close' do
      pool.state = "ERROR"
      expect(pool).not_to be_valid
      expect(pool.errors.details[:state]).to include({:error => :inclusion, :value => "ERROR"})
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

  describe 'Methods events' do
    it 'Add event to a Pool' do
      count = pool.showback_events.count
      pool.add_event(event)
      expect(pool.showback_events.count).to eq(count + 1)
      expect(pool.showback_events).to include(event)
    end

    it 'Throw error in Add event to a Pool if it is a duplicate' do
      pool.add_event(event)
      pool.add_event(event)
      expect(pool.errors.details[:showback_events]). to include(:error => "duplicate")
    end

    it 'Throw error in add event if it is not of a proper type' do
      obj = FactoryGirl.create(:vm)
      pool.add_event(obj)
      expect(pool.errors.details[:showback_events]). to include(:error => "Error Type #{obj.type} is not ManageIQ::Consumption::ShowbackEvent")
    end

    it 'Remove event from a Pool' do
      pool.add_event(event)
      count = pool.showback_events.count
      pool.remove_event(event)
      expect(pool.showback_events.count).to eq(count - 1)
      expect(pool.showback_events).not_to include(event)
    end

    it 'Throw error in Remove event from a Pool if the event can not be found' do
      pool.add_event(event)
      pool.remove_event(event)
      pool.remove_event(event)
      expect(pool.errors.details[:showback_events]). to include(:error => "not found")
    end

    it 'Throw error in Remove event if the type is not correct' do
      obj = FactoryGirl.create(:vm)
      pool.remove_event(obj)
      expect(pool.errors.details[:showback_events]). to include(:error => "Error Type #{obj.type} is not ManageIQ::Consumption::ShowbackEvent")
    end
  end

  describe 'methods with #showback_charge' do
    it 'add charge directly' do
      charge = FactoryGirl.create(:showback_charge, :showback_pool => pool)
      pool.add_charge(charge, 2)
      expect(charge.cost). to eq(Money.new(2))
    end

    it 'add charge directly' do
      charge = FactoryGirl.create(:showback_charge, :cost => Money.new(7)) # different pool
      pool.add_charge(charge, 2)
      expect(charge.cost).not_to eq(Money.new(2))
    end

    it 'add charge from an event' do
      event  = FactoryGirl.create(:showback_event)
      charge = FactoryGirl.create(:showback_charge, :showback_event => event)
      expect(event.showback_charges).to include(charge)
    end

    it 'get_charge' do
      charge = FactoryGirl.create(:showback_charge, :showback_pool => pool, :cost => Money.new(10))
      expect(pool.get_charge(charge)).to eq(Money.new(10))
    end

    it 'get_charge with nil' do
      expect(pool.get_charge(nil)).to eq(0)
    end

    it 'calculate_charge with an error' do
      charge = FactoryGirl.create(:showback_charge, :cost => Money.new(10))
      pool.calculate_charge(charge)
      expect(charge.errors.details[:showback_charge]). to include(:error => 'not found')
      expect(pool.calculate_charge(charge)). to eq(Money.new(0))
    end

    it 'calculate_charge fail with no charge' do
      enterprise_plan
      expect(pool.find_price_plan).to eq(ManageIQ::Consumption::ShowbackPricePlan.first)
      pool.calculate_charge(nil)
      expect(pool.errors.details[:showback_charge]). to include(:error => "not found")
      expect(pool.calculate_charge(nil)). to eq(0)
    end

    it 'Find a price plan' do
      ManageIQ::Consumption::ShowbackPricePlan.seed
      expect(pool.find_price_plan).to eq(ManageIQ::Consumption::ShowbackPricePlan.first)
    end

    it '#calculate charge' do
      enterprise_plan
      FactoryGirl.create(:showback_rate,
                         :fixed_rate => Money.new(67),
                         :variable_rate => Money.new(12),
                         :category => 'CPU',
                         :dimension => 'average',
                         :showback_price_plan => ManageIQ::Consumption::ShowbackPricePlan.first)
      pool.add_event(event2)
      event2.reload
      pool.showback_charges.reload
      charge = pool.showback_charges.find_by(:showback_event => event2)
      charge.cost = Money.new(0)
      expect { pool.calculate_charge(charge) }.to change(charge, :cost).
          from(Money.new(0)).to(Money.new((event2.data['CPU']['average'] * 12) + 67))
    end

    it '#Add an event' do
      event = FactoryGirl.create(:showback_event)
      expect { pool.add_charge(event, 5) }.to change(pool.showback_charges, :count).by(1)
    end

    it 'update a charge in the pool with add_charge' do
      charge = FactoryGirl.create(:showback_charge, :showback_pool => pool)
      expect { pool.add_charge(charge, 5) }.to change(charge, :cost).to(Money.new(5))
    end

    it 'update a charge in the pool with update_charge' do
      charge = FactoryGirl.create(:showback_charge, :showback_pool => pool)
      expect { pool.update_charge(charge, 5) }.to change(charge, :cost).to(Money.new(5))
    end

    it 'update a charge in the pool gets nil if the charge is not there' do
      charge = FactoryGirl.create(:showback_charge) # not in the pool
      expect(pool.update_charge(charge, 5)).to be_nil
    end

    it '#clear_charge' do
      pool.add_event(event)
      pool.showback_charges.reload
      charge = pool.showback_charges.find_by(:showback_event => event)
      charge.cost = Money.new(5)
      expect { pool.clear_charge(charge) }.to change(charge, :cost).from(Money.new(5)).to(Money.new(0))
    end

    it '#clear all charges' do
      pool.add_charge(event, Money.new(57))
      pool.add_charge(event2, Money.new(123))
      pool.clean_all_charges
      pool.showback_charges.each do |x|
        expect(x.cost).to eq(Money.new(0))
      end
    end

    it '#sum_of_charges' do
      pool.add_charge(event, Money.new(57))
      pool.add_charge(event2, Money.new(123))
      expect(pool.sum_of_charges).to eq(Money.new(180))
    end

    it 'calculate_all_charges' do
      enterprise_plan
      FactoryGirl.create(:showback_rate,
                         :fixed_rate => Money.new(67),
                         :variable_rate => Money.new(12),
                         :category => 'CPU',
                         :dimension => 'average',
                         :showback_price_plan => ManageIQ::Consumption::ShowbackPricePlan.first)
      pool.add_event(event)
      pool.add_event(event2)
      event.reload
      event2.reload
      pool.showback_charges.reload
      pool.showback_charges.each do |x|
        expect(x.cost).to eq(Money.new(0))
      end
      pool.showback_charges.reload
      pool.calculate_all_charges
      pool.showback_charges.each do |x|
        expect(x.cost).not_to eq(Money.new(0))
      end
    end
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