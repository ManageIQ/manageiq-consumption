require 'spec_helper'
require 'money-rails/test_helpers'

RSpec.describe ManageIQ::Consumption::ShowbackCharge, :type => :model do
  context 'basic life cycle' do
    let(:charge) { FactoryGirl.build(:showback_charge) }
    let(:cost)   { Money.new(1) }

    it 'has a valid factory' do
      expect(charge).to be_valid
    end

    it 'monetizes cost' do
      expect(described_class).to monetize(:cost)
      expect(charge).to monetize(:cost)
    end

    it 'cost defaults to 0' do
      expect(described_class.new.cost).to eq(Money.new(0))
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
      expect(charge.cost).to eq(Money.new(0)) # default is 0
    end
  end

  context '#calculate_cost' do
    let(:cost)   { Money.new(32) }
    let(:pool)   { FactoryGirl.create(:showback_pool) }
    let!(:plan)          { FactoryGirl.create(:showback_price_plan) } # By default is :enterprise
    let(:plan2)          { FactoryGirl.create(:showback_price_plan) }
    let(:fixed_rate1)    { Money.new(3) }
    let(:fixed_rate2)    { Money.new(5) }
    let(:variable_rate1) { Money.new(7) }
    let(:variable_rate2) { Money.new(7) }
    let(:rate1) do
      FactoryGirl.create(:showback_rate,
                         :showback_price_plan => plan,
                         :dimension           => 'CPU#average',
                         :fixed_rate          => fixed_rate1,
                         :variable_rate       => variable_rate1)
    end

    let(:rate2) do
      FactoryGirl.create(:showback_rate,
                         :showback_price_plan => plan2,
                         :dimension           => 'CPU#average',
                         :fixed_rate          => fixed_rate2,
                         :variable_rate       => variable_rate2)
    end

    let(:event) do
      FactoryGirl.build(:showback_event,
                        :with_vm_data,
                        :full_month)
    end

    let(:charge) do
      FactoryGirl.build(:showback_charge,
                        :showback_pool  => pool,
                        :cost           => cost,
                        :showback_event => event)
    end

    context 'without price_plan' do
      it 'calculates cost using default price plan' do
        rate1
        event.save
        event.reload
        charge.save
        expect(event.data).not_to be_nil # making sure that the default is not empty
        expect(ManageIQ::Consumption::ShowbackPricePlan.count).to eq(1)
        expect(charge.showback_event).to eq(event)
        expect(charge.calculate_cost).to eq(fixed_rate1 + variable_rate1 * event.data['Vm']['CPU']['average'])
      end
    end
    context 'with price_plan' do
      it 'calculates cost using price plan' do
        rate1
        rate2
        event.save
        event.reload
        charge.save
        expect(event.data).not_to be_nil
        plan2
        expect(ManageIQ::Consumption::ShowbackPricePlan.count).to eq(2)
        expect(charge.showback_event).to eq(event)
        # Test that it works without a plan
        expect(charge.calculate_cost).to eq(fixed_rate1 + variable_rate1 * event.data['Vm']['CPU']['average'])
        # Test that it changes if you provide a plan
        expect(charge.calculate_cost(plan2)).to eq(fixed_rate2 + variable_rate2 * event.data['Vm']['CPU']['average'])
      end

      it 'raises an error if the plan provider is not working' do
        rate1
        rate2
        event.save
        event.reload
        charge.save
        expect(event.data).not_to be_nil
        expect(ManageIQ::Consumption::ShowbackPricePlan.count).to eq(2)
        expect(charge.showback_event).to eq(event)
        # Test that it works without a plan
        expect(charge.calculate_cost).to eq(fixed_rate1 + variable_rate1 * event.data['Vm']['CPU']['average'])
        # Test that it changes if you provide a plan
        expect(charge.calculate_cost("ERROR")).to eq(Money.new(0))
        expect(charge.errors.details[:showback_price_plan]).to include({ :error => "not found" })
      end
    end
  end
end
