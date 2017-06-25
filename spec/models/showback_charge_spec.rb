require 'spec_helper'
require 'money-rails/test_helpers'

RSpec.describe ManageIQ::Consumption::ShowbackCharge, :type => :model do
  let(:charge) { FactoryGirl.build(:showback_charge) }
  let(:cost) { Money.new(1) }

  context 'basic life cycle' do
    it 'has a valid factory' do
      expect(charge).to be_valid
    end

    it 'monetizes cost' do
      expect(described_class).to monetize(:cost)
      expect(charge).to monetize(:cost)
    end

    it 'you can add a charge without cost' do
      charge.cost = nil
      charge.valid?
      expect(charge).to be_valid
    end

    it 'you can add a charge with cost' do
      charge.cost = cost
      charge.valid?
      expect(charge).to be_valid
    end

    it 'you can read charges' do
      charge.cost = cost
      charge.save
      expect(charge.reload.cost).to eq(cost)
    end

    it 'can delete cost' do
      charge.cost = Money.new(10)
      charge.save
      charge.clean_cost
      charge.reload
      expect(charge.cost).to eq(Money.new(0))
    end
  end

  context '#calculate_cost' do
    let!(:plan)          { FactoryGirl.create(:showback_price_plan) }
    let(:fixed_rate1)    { Money.new(3) }
    let(:fixed_rate2)    { Money.new(5) }
    let(:variable_rate1) { Money.new(7) }
    let(:variable_rate2) { Money.new(7) }
    let(:cost1)          { Money.new(32) }
    let(:cost2)          { Money.new(35) }
    let(:pool) { FactoryGirl.create(:showback_pool) }
    let(:rate1) do
      FactoryGirl.create(:showback_rate,
                         :showback_price_plan => plan,
                         :category            => 'CPU',
                         :dimension           => 'average',
                         :fixed_rate          => fixed_rate1,
                         :variable_rate       => variable_rate1)
    end
    let(:event1) do
      FactoryGirl.create(:showback_event,
                         :with_vm_data,
                         :full_month)
    end
    let(:event2) do
      FactoryGirl.create(:showback_event,
                         :with_vm_data,
                         :full_month)
    end
    let(:charge1) do
      FactoryGirl.create(:showback_charge,
                         :showback_pool  => pool,
                         :cost           => cost1,
                         :showback_event => event1)
    end
    let(:charge2) do
      FactoryGirl.create(:showback_charge,
                         :showback_pool  => pool,
                         :cost     => cost2,
                         :showback_event => event2)
    end

    context 'with price_plan' do
      pending 'calculates cost using price plan' do
        plan
        rate1
        expect(event1.data).not_to be_nil
        expect(ManageIQ::Consumption::ShowbackPricePlan.count).to eq(1)
        expect(charge1.showback_event).to eq(event1)
        expect(charge1.calculate_cost).to eq(fixed_rate1 + fixed_rate2 + variable_rate1 + variable_rate2)

      end
    end
    context 'without price_plan' do
      pending 'calculates cost finding price plan for the resource'
    end
  end
end