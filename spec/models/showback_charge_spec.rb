require 'spec_helper'
require 'money-rails/test_helpers'

RSpec.describe ManageIQ::Consumption::ShowbackCharge, :type => :model do
  before(:each) do
    ManageIQ::Consumption::ShowbackUsageType.seed
  end

  context 'basic life cycle' do
    let(:charge) { FactoryGirl.build(:showback_charge) }
    let(:cost) { Money.new(1) }

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

  context '#validate price_plan_missing and snapshot' do
    let(:event) do
      FactoryGirl.build(:showback_event,
                        :with_vm_data,
                        :full_month)
    end

    let(:charge) do
      FactoryGirl.build(:showback_charge,
                        :showback_event => event)
    end

    it "fails if can't find a price plan" do
      event.save
      event.reload
      charge.save
      expect(ManageIQ::Consumption::ShowbackPricePlan.count).to eq(0)
      expect(charge.calculate_cost).to eq(Money.new(0))
    end

    it "fails if snapshot of charge is not the event data after create" do
      event.save
      charge.save
      expect(charge.stored_data.first[1]).to eq(event.data)
      event.data = {"CPU" => {"average" => [2, "percent"], "max_number_of_cpu" => [40, "cores"]}}
      event.save
      charge.save
      expect(charge.stored_data.first[1]).not_to eq(event.data)
    end

    it "Return the stored data at start" do
      event.save
      charge.save
      expect(charge.stored_data_start).to eq(event.data)
    end

    it "Return the last stored data" do
      event.save
      charge.save
      expect(charge.stored_data.length).to eq(1)
      event.data = {"CPU" => {"average" => [2, "percent"], "max_number_of_cpu" => [40, "cores"]}}
      charge.update_stored_data
      expect(charge.stored_data_last).to eq(event.data)
    end

    it "Return the last stored data key" do
      event.save
      charge.stored_data = { 3.hours.ago  => {"CPU" => {"average" => [2, "percent"], "max_number_of_cpu" => [40, "cores"]}},
                             Time.now.utc => {"CPU" => {"average" => [2, "percent"], "max_number_of_cpu" => [40, "cores"]}}}
      t = charge.stored_data.keys.sort.last
      expect(charge.stored_data_last_key).to eq(t)
    end
  end

  context '#stored data' do
    let(:charge_data) { FactoryGirl.build(:showback_charge, :with_stored_data) }
    let(:event_for_charge) { FactoryGirl.create(:showback_event) }
    let(:pool_of_event) do
      FactoryGirl.create(:showback_pool,
                         :resource => event_for_charge.resource)
    end

    it "stored event" do
      event_for_charge.data = {
        "CPU"    => {
          "average"           => [29.8571428571429, "percent"],
          "number"            => [2.0, "cores"],
          "max_number_of_cpu" => [2, "cores"]
        },
        "MEM"    => {
          "max_mem" => [2048, "Mib"]
        },
        "FLAVOR" => {}
      }
      charge1 = FactoryGirl.create(:showback_charge,
                                   :showback_pool  => pool_of_event,
                                   :showback_event => event_for_charge)
      expect(charge1.stored_data_start).to eq(event_for_charge.data)
      charge1.stored_data_event
      expect(charge1.stored_data_start).to eq(event_for_charge.data)
    end

    it "get measure" do
      expect(charge_data.get_measure("CPU", "number")).to eq([2.0, "cores"])
    end

    it "get last measure" do
      expect(charge_data.get_last_measure("CPU", "number")).to eq([4.0, "cores"])
    end

    it "get pool measure" do
      expect(charge_data.get_pool_measure("CPU", "number")).to eq([[2.0, "cores"], [4.0, "cores"]])
    end
  end
  context '#calculate_cost' do
    let(:cost)           { Money.new(32) }
    let(:pool)           { FactoryGirl.create(:showback_pool) }
    let!(:plan)          { FactoryGirl.create(:showback_price_plan) } # By default is :enterprise
    let(:plan2)          { FactoryGirl.create(:showback_price_plan) }
    let(:fixed_rate1)    { Money.new(3) }
    let(:fixed_rate2)    { Money.new(5) }
    let(:variable_rate1) { Money.new(7) }
    let(:variable_rate2) { Money.new(7) }
    let(:rate1) do
      FactoryGirl.create(:showback_rate,
                         :CPU_average,
                         :showback_price_plan => plan)
    end
    let(:showback_tier1) { rate1.showback_tiers.first }
    let(:rate2) do
      FactoryGirl.create(:showback_rate,
                         :CPU_average,
                         :showback_price_plan => plan2)
    end
    let(:showback_tier2) { rate2.showback_tiers.first }
    let(:event) do
      FactoryGirl.create(:showback_event,
                         :with_vm_data,
                         :full_month)
    end

    let(:charge) do
      FactoryGirl.create(:showback_charge,
                         :showback_pool  => pool,
                         :cost           => cost,
                         :showback_event => event)
    end

    context 'without price_plan' do
      it 'calculates cost using default price plan' do
        rate1
        event.reload
        charge.save
        showback_tier1
        showback_tier1.fixed_rate = fixed_rate1
        showback_tier1.variable_rate = variable_rate1
        showback_tier1.variable_rate_per_unit = "percent"
        showback_tier1.save
        expect(event.data).not_to be_nil # making sure that the default is not empty
        expect(ManageIQ::Consumption::ShowbackPricePlan.count).to eq(1)
        expect(charge.showback_event).to eq(event)
        expect(charge.calculate_cost).to eq(fixed_rate1 + variable_rate1 * event.data['CPU']['average'].first)
      end
    end
    context 'with price_plan' do
      it 'calculates cost using price plan' do
        rate1.reload
        rate2.reload
        event.reload
        charge.save
        showback_tier1
        showback_tier1.fixed_rate = fixed_rate1
        showback_tier1.variable_rate = variable_rate1
        showback_tier1.variable_rate_per_unit = "percent"
        showback_tier1.save
        showback_tier2
        showback_tier2.fixed_rate = fixed_rate2
        showback_tier2.variable_rate = variable_rate2
        showback_tier2.variable_rate_per_unit = "percent"
        showback_tier2.save
        expect(event.data).not_to be_nil
        plan2.reload
        expect(ManageIQ::Consumption::ShowbackPricePlan.count).to eq(2)
        expect(charge.showback_event).to eq(event)
        # Test that it works without a plan
        expect(charge.calculate_cost).to eq(fixed_rate1 + variable_rate1 * event.get_measure_value('CPU', 'average'))
        # Test that it changes if you provide a plan
        expect(charge.calculate_cost(plan2)).to eq(fixed_rate2 + variable_rate2 * event.get_measure_value('CPU', 'average'))
      end

      it 'raises an error if the plan provider is not working' do
        rate1
        rate2
        event.reload
        charge.save
        showback_tier1
        showback_tier1.fixed_rate = fixed_rate1
        showback_tier1.variable_rate = variable_rate1
        showback_tier1.variable_rate_per_unit = "percent"
        showback_tier1.save
        showback_tier2
        showback_tier2.fixed_rate = fixed_rate2
        showback_tier2.variable_rate = variable_rate2
        showback_tier2.variable_rate_per_unit = "percent"
        showback_tier2.save
        expect(event.data).not_to be_nil
        expect(ManageIQ::Consumption::ShowbackPricePlan.count).to eq(2)
        expect(charge.showback_event).to eq(event)
        # Test that it works without a plan
        expect(charge.calculate_cost).to eq(fixed_rate1 + variable_rate1 * event.get_measure_value('CPU', 'average'))
        # Test that it changes if you provide a plan
        expect(charge.calculate_cost('ERROR')).to eq(Money.new(0))
        expect(charge.errors.details[:showback_price_plan]).to include(:error => 'not found')
      end
    end
  end
end
