require 'spec_helper'
require 'money-rails/test_helpers'

RSpec.describe ManageIQ::Consumption::ShowbackEnvelope, :type => :model do
  before(:each) do
    ManageIQ::Consumption::InputMeasure.seed
  end
  let(:resource)        { FactoryGirl.create(:vm) }
  let(:pool)            { FactoryGirl.build(:showback_envelope) }
  let(:data_rollup)           { FactoryGirl.build(:data_rollup, :with_vm_data, :full_month, :resource => resource) }
  let(:data_rollup2)          { FactoryGirl.build(:data_rollup, :with_vm_data, :full_month, :resource => resource) }
  let(:enterprise_plan) { FactoryGirl.create(:showback_price_plan) }

  context '#basic lifecycle' do
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

    it 'monetizes accumulated cost' do
      expect(ManageIQ::Consumption::ShowbackEnvelope).to monetize(:accumulated_cost)
    end

    it 'deletes costs associated when deleting the pool' do
      2.times do
        FactoryGirl.create(:showback_data_view, :showback_envelope => pool)
      end
      expect(pool.showback_data_views.count).to be(2)
      expect { pool.destroy }.to change(ManageIQ::Consumption::ShowbackDataView, :count).from(2).to(0)
      expect(pool.showback_data_views.count).to be(0)
    end

    it 'deletes costs associated when deleting the data_rollup' do
      2.times do
        FactoryGirl.create(:showback_data_view, :showback_envelope => pool)
      end
      expect(pool.showback_data_views.count).to be(2)
      d_rollup = pool.showback_data_views.first.data_rollup
      expect { d_rollup.destroy }.to change(ManageIQ::Consumption::ShowbackDataView, :count).from(2).to(1)
      expect(pool.data_rollups).not_to include(data_rollup)
    end

    it 'it only can be in approved states' do
      pool.state = 'ERROR'
      expect(pool).not_to be_valid
      expect(pool.errors.details[:state]).to include(:error => :inclusion, :value => 'ERROR')
    end

    it 'it can not be different of states open, processing, closed' do
      states = %w(CLOSED PROCESSING OPEN)
      states.each do |x|
        pool.state = x
        expect(pool).to be_valid
      end
    end

    it 'start time should happen earlier than end time' do
      pool.start_time = pool.end_time
      pool.valid?
      expect(pool.errors.details[:end_time]).to include(:error => 'should happen after start_time')
    end
  end

  context '.control lifecycle state' do
    let(:pool_lifecycle) { FactoryGirl.create(:showback_envelope) }

    it 'it can transition from open to processing' do
      pool_lifecycle.state = 'PROCESSING'
      pool_lifecycle.valid?
      expect(pool).to be_valid
    end

    it 'a new pool is created automatically when transitioning from open to processing if not exists' do
      pool_lifecycle.state = 'PROCESSING'
      pool_lifecycle.save
      # There should be two pools when I save, the one in processing state + the one in OPEN state
      expect(described_class.count).to eq(2)
      # ERROR ERROR ERROR
    end

    it 'it can not transition from open to closed' do
      pool_lifecycle.state = 'CLOSED'
      expect { pool_lifecycle.save }.to raise_error(RuntimeError, _("Pool can't change state to CLOSED from OPEN"))
    end

    it 'it can not transition from processing to open' do
      pool_lifecycle = FactoryGirl.create(:showback_envelope, :processing)
      pool_lifecycle.state = 'OPEN'
      expect { pool_lifecycle.save }.to raise_error(RuntimeError, _("Pool can't change state to OPEN from PROCESSING"))
    end

    it 'it can transition from processing to closed' do
      pool_lifecycle = FactoryGirl.create(:showback_envelope, :processing)
      pool_lifecycle.state = 'CLOSED'
      expect { pool_lifecycle.save }.not_to raise_error
    end

    it 'it can not transition from closed to open or processing' do
      pool_lifecycle = FactoryGirl.create(:showback_envelope, :closed)
      pool_lifecycle.state = 'OPEN'
      expect { pool_lifecycle.save }.to raise_error(RuntimeError, _("Pool can't change state when it's CLOSED"))
      pool_lifecycle = FactoryGirl.create(:showback_envelope, :closed)
      pool_lifecycle.state = 'PROCESSING'
      expect { pool_lifecycle.save }.to raise_error(RuntimeError, _("Pool can't change state when it's CLOSED"))
    end

    pending 'it can not exists 2 pools opened from one resource'
  end

  describe 'methods for data_rollups' do
    it 'can add an data_rollup to a pool' do
      expect { pool.add_data_rollup(data_rollup) }.to change(pool.data_rollups, :count).by(1)
      expect(pool.data_rollups).to include(data_rollup)
    end

    it 'throws an error for duplicate data_rollups when using Add data_rollup to a Pool' do
      pool.add_data_rollup(data_rollup)
      pool.add_data_rollup(data_rollup)
      expect(pool.errors.details[:data_rollups]). to include(:error => "duplicate")
    end

    it 'Throw error in add data_rollup if it is not of a proper type' do
      obj = FactoryGirl.create(:vm)
      pool.add_data_rollup(obj)
      expect(pool.errors.details[:data_rollups]). to include(:error => "Error Type #{obj.type} is not ManageIQ::Consumption::DataRollup")
    end

    it 'Remove data_rollup from a Pool' do
      pool.add_data_rollup(data_rollup)
      expect { pool.remove_data_rollup(data_rollup) }.to change(pool.data_rollups, :count).by(-1)
      expect(pool.data_rollups).not_to include(data_rollup)
    end

    it 'Throw error in Remove data_rollup from a Pool if the data_rollup can not be found' do
      pool.add_data_rollup(data_rollup)
      pool.remove_data_rollup(data_rollup)
      pool.remove_data_rollup(data_rollup)
      expect(pool.errors.details[:data_rollups]). to include(:error => "not found")
    end

    it 'Throw error in Remove data_rollup if the type is not correct' do
      obj = FactoryGirl.create(:vm)
      pool.remove_data_rollup(obj)
      expect(pool.errors.details[:data_rollups]). to include(:error => "Error Type #{obj.type} is not ManageIQ::Consumption::DataRollup")
    end
  end

  describe 'methods with #showback_data_view' do
    it 'add charge directly' do
      charge = FactoryGirl.create(:showback_data_view, :showback_envelope => pool)
      pool.add_charge(charge, 2)
      expect(charge.cost). to eq(Money.new(2))
    end

    it 'add charge directly' do
      charge = FactoryGirl.create(:showback_data_view, :cost => Money.new(7)) # different pool
      pool.add_charge(charge, 2)
      # Charge won't be updated as it does not belongs to the pool
      expect(charge.cost).not_to eq(Money.new(2))
      expect(charge.showback_envelope).not_to eq(pool)
    end

    it 'add charge from an data_rollup' do
      data_rollup = FactoryGirl.create(:data_rollup)
      charge = FactoryGirl.create(:showback_data_view, :data_rollup => data_rollup, :showback_envelope => pool)
      expect(data_rollup.showback_data_views).to include(charge)
      expect(pool.showback_data_views).to include(charge)
    end

    it 'get_charge from a charge' do
      charge = FactoryGirl.create(:showback_data_view, :showback_envelope => pool, :cost => Money.new(10))
      expect(pool.get_charge(charge)).to eq(Money.new(10))
    end

    it 'get_charge from an data_rollup' do
      charge = FactoryGirl.create(:showback_data_view, :showback_envelope => pool, :cost => Money.new(10))
      data_rollup = charge.data_rollup
      expect(pool.get_charge(data_rollup)).to eq(Money.new(10))
    end

    it 'get_charge from nil get 0' do
      expect(pool.get_charge(nil)).to eq(0)
    end

    it 'calculate_charge with an error' do
      charge = FactoryGirl.create(:showback_data_view, :cost => Money.new(10))
      pool.calculate_charge(charge)
      expect(charge.errors.details[:showback_data_view]). to include(:error => 'not found')
      expect(pool.calculate_charge(charge)). to eq(Money.new(0))
    end

    it 'calculate_charge fails with no charge' do
      enterprise_plan
      expect(pool.find_price_plan).to eq(ManageIQ::Consumption::ShowbackPricePlan.first)
      pool.calculate_charge(nil)
      expect(pool.errors.details[:showback_data_view]). to include(:error => "not found")
      expect(pool.calculate_charge(nil)). to eq(0)
    end

    it 'find a price plan' do
      ManageIQ::Consumption::ShowbackPricePlan.seed
      expect(pool.find_price_plan).to eq(ManageIQ::Consumption::ShowbackPricePlan.first)
    end

    pending 'find a price plan associated to the resource'
    pending 'find a price plan associated to a parent resource'
    pending 'find a price plan finds the default price plan if not found'

    it '#calculate charge' do
      enterprise_plan
      sh = FactoryGirl.create(:showback_rate,
                              :CPU_average,
                              :showback_price_plan => ManageIQ::Consumption::ShowbackPricePlan.first)
      st = sh.showback_tiers.first
      st.fixed_rate = Money.new(67)
      st.variable_rate = Money.new(12)
      st.variable_rate_per_unit = 'percent'
      st.save
      pool.add_data_rollup(data_rollup2)
      data_rollup2.reload
      pool.showback_data_views.reload
      charge = pool.showback_data_views.find_by(:data_rollup => data_rollup2)
      charge.cost = Money.new(0)
      charge.save
      expect { pool.calculate_charge(charge) }.to change(charge, :cost)
        .from(Money.new(0)).to(Money.new((data_rollup2.reload.get_group_value('CPU', 'average') * 12) + 67))
    end

    it '#Add an data_rollup' do
      data_rollup = FactoryGirl.create(:data_rollup)
      expect { pool.add_charge(data_rollup, 5) }.to change(pool.showback_data_views, :count).by(1)
    end

    it 'update a charge in the pool with add_charge' do
      charge = FactoryGirl.create(:showback_data_view, :showback_envelope => pool)
      expect { pool.add_charge(charge, 5) }.to change(charge, :cost).to(Money.new(5))
    end

    it 'update a charge in the pool with update_charge' do
      charge = FactoryGirl.create(:showback_data_view, :showback_envelope => pool)
      expect { pool.update_charge(charge, 5) }.to change(charge, :cost).to(Money.new(5))
    end

    it 'update a charge in the pool gets nil if the charge is not there' do
      charge = FactoryGirl.create(:showback_data_view) # not in the pool
      expect(pool.update_charge(charge, 5)).to be_nil
    end

    it '#clear_charge' do
      pool.add_data_rollup(data_rollup)
      pool.showback_data_views.reload
      charge = pool.showback_data_views.find_by(:data_rollup => data_rollup)
      charge.cost = Money.new(5)
      expect { pool.clear_charge(charge) }.to change(charge, :cost).from(Money.new(5)).to(Money.new(0))
    end

    it '#clear all charges' do
      pool.add_charge(data_rollup, Money.new(57))
      pool.add_charge(data_rollup2, Money.new(123))
      pool.clean_all_charges
      pool.showback_data_views.each do |x|
        expect(x.cost).to eq(Money.new(0))
      end
    end

    it '#sum_of_charges' do
      pool.add_charge(data_rollup, Money.new(57))
      pool.add_charge(data_rollup2, Money.new(123))
      expect(pool.sum_of_charges).to eq(Money.new(180))
    end

    it 'calculate_all_charges' do
      enterprise_plan
      vm = FactoryGirl.create(:vm)
      sh = FactoryGirl.create(:showback_rate,
                              :CPU_average,
                              :showback_price_plan => ManageIQ::Consumption::ShowbackPricePlan.first)
      tier = sh.showback_tiers.first
      tier.fixed_rate    = Money.new(67)
      tier.variable_rate = Money.new(12)
      tier.save
      ev  = FactoryGirl.create(:data_rollup, :with_vm_data, :full_month, :resource => vm)
      ev2 = FactoryGirl.create(:data_rollup, :with_vm_data, :full_month, :resource => vm)
      pool.add_data_rollup(ev)
      pool.add_data_rollup(ev2)
      pool.showback_data_views.reload
      pool.showback_data_views.each do |x|
        expect(x.cost).to eq(Money.new(0))
      end
      pool.showback_data_views.reload
      pool.calculate_all_charges
      pool.showback_data_views.each do |x|
        expect(x.cost).not_to eq(Money.new(0))
      end
    end
  end

  describe '#state:open' do
    it 'new data_rollups can be associated to the pool' do
      pool.save
      # data_rollup.save
      data_rollup
      expect { pool.data_rollups << data_rollup }.to change(pool.data_rollups, :count).by(1)
      expect(pool.data_rollups.last).to eq(data_rollup)
    end
    it 'data_rollups can be associated to costs' do
      pool.save
      # data_rollup.save
      data_rollup
      expect { pool.data_rollups << data_rollup }.to change(pool.showback_data_views, :count).by(1)
      charge = pool.showback_data_views.last
      expect(charge.data_rollup).to eq(data_rollup)
      expect { charge.cost = Money.new(3) }.to change(charge, :cost).from(0).to(Money.new(3))
    end

    it 'monetized cost' do
      expect(ManageIQ::Consumption::ShowbackDataView).to monetize(:cost)
    end

    pending 'charges can be updated for an data_rollup'
    pending 'charges can be updated for all data_rollups in the pool'
    pending 'charges can be deleted for an data_rollup'
    pending 'charges can be deleted for all data_rollups in the pool'
    pending 'is possible to return charges for an data_rollup'
    pending 'is possible to return charges for all data_rollups'
    pending 'sum of charges can be calculated for the pool'
    pending 'sum of charges can be calculated for an data_rollup type'
  end

  describe '#state:processing' do
    pending 'new data_rollups are associated to a new or open pool'
    pending 'new data_rollups can not be associated to the pool'
    pending 'charges can be deleted for an data_rollup'
    pending 'charges can be deleted for all data_rollups in the pool'
    pending 'charges can be updated for an data_rollup'
    pending 'charges can be updated for all data_rollups in the pool'
    pending 'is possible to return charges for an data_rollup'
    pending 'is possible to return charges for all data_rollups'
    pending 'sum of charges can be calculated for the pool'
    pending 'sum of charges can be calculated for an data_rollup type'
  end

  describe '#state:closed' do
    pending 'new data_rollups can not be associated to the pool'
    pending 'new data_rollups are associated to a new or existing open pool'
    pending 'charges can not be deleted for an data_rollup'
    pending 'charges can not be deleted for all data_rollups in the pool'
    pending 'charges can not be updated for an data_rollup'
    pending 'charges can not be updated for all data_rollups in the pool'
    pending 'is possible to return charges for an data_rollup'
    pending 'is possible to return charges for all data_rollups'
    pending 'sum of charges can be calculated for the pool'
    pending 'sum of charges can be calculated for an data_rollup type'
  end
end
