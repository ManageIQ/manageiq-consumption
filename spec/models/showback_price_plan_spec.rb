require 'spec_helper'
require 'money-rails/test_helpers'

RSpec.describe ManageIQ::Consumption::ShowbackPricePlan, :type => :model do
  # We need to ShowbackUsageType list to know what measures we should be looking for
  before(:all) do
    ManageIQ::Consumption::ShowbackUsageType.seed
  end

  context 'basic tests' do
    let(:plan) { FactoryGirl.build(:showback_price_plan) }

    it 'has a valid factory' do
      plan.valid?
      expect(plan).to be_valid
    end

    it 'is not valid without a name' do
      plan.name = nil
      plan.valid?
      expect(plan.errors.details[:name]). to include(:error => :blank)
    end

    it 'is not valid without a description' do
      plan.description = nil
      plan.valid?
      expect(plan.errors.details[:description]). to include(:error => :blank)
    end

    it 'is not valid without an association to a parent element' do
      plan.resource = nil
      plan.valid?
      expect(plan.errors.details[:resource]). to include(:error => :blank)
    end

    it 'is possible to add new rates to the price plan' do
      plan.save
      rate = FactoryGirl.build(:showback_rate, :showback_price_plan => plan)
      expect { rate.save }.to change(plan.showback_rates, :count).from(0).to(1)
    end

    it 'rates are deleted when deleting the plan' do
      FactoryGirl.create(:showback_rate, :showback_price_plan => plan)
      FactoryGirl.create(:showback_rate, :showback_price_plan => plan)
      expect(plan.showback_rates.count).to be(2)
      expect { plan.destroy }.to change(ManageIQ::Consumption::ShowbackRate, :count).from(2).to(0)
    end

    context 'rating with no context' do
      let(:resource)       { FactoryGirl.create(:vm) }
      let(:event)          { FactoryGirl.build(:showback_event, :with_vm_data, :full_month, resource: resource) }
      let(:fixed_rate)     { Money.new(11) }
      let(:variable_rate)  { Money.new(7) }
      let(:fixed_rate2)    { Money.new(5) }
      let(:variable_rate2) { Money.new(13) }
      let(:dimension)      { 'CPU#average' }
      let(:dimension2)     { 'CPU#max_number_of_cpu' }
      let(:plan)  { FactoryGirl.create(:showback_price_plan) }
      let(:rate)  do
        FactoryGirl.build(:showback_rate,
                          :showback_price_plan => plan,
                          :fixed_rate          => fixed_rate,
                          :variable_rate       => variable_rate,
                          :dimension           => dimension)
      end
      let(:rate2) do
        FactoryGirl.build(:showback_rate,
                          :showback_price_plan => plan,
                          :fixed_rate          => fixed_rate2,
                          :variable_rate       => variable_rate2,
                          :dimension           => dimension2)
      end

      it 'calculates costs when rate is not found' do
        event.save
        event.reload
        # test that the event has the information we need in data
        expect(event.data['CPU']).not_to be_nil
        expect(event.data['CPU']['average']).not_to be_nil
        expect(event.data['CPU']['max_number_of_cpu']).not_to be_nil
        # Make rate category not found
        rate.category = 'not-found'
        rate.save
        expect(plan.calculate_total_cost(event)).to eq(Money.new(0))
      end

      it 'calculates costs when rate is not found and event data' do
        rate.category = 'not-found'
        rate.save
        category = event.resource.type
        data = event.data
        time_span = event.time_span
        cycle_duration = event.month_duration
        context = event.context
        expect(plan.calculate_total_cost_input(category, data, time_span, cycle_duration, context)).to eq(plan.calculate_total_cost(event))
      end

      it 'calculates costs with one rate' do
        event.save
        event.reload
        # test that the event has the information we need in data
        expect(event.data['CPU']).not_to be_nil
        expect(event.data['CPU']['average']).not_to be_nil
        expect(event.data['CPU']['max_number_of_cpu']).not_to be_nil
        rate.dimension = 'CPU#max_number_of_cpu'
        rate.save
        # Rating now should return the value
        expect(plan.calculate_total_cost(event)).to eq(Money.new(39))
      end

      it 'calculates costs when more than one rate applies' do
        event.save
        event.reload
        # test that the event has the information we need in data
        expect(event.data['CPU']).not_to be_nil
        expect(event.data['CPU']['average']).not_to be_nil
        expect(event.data['CPU']['max_number_of_cpu']).not_to be_nil
        rate.dimension = 'CPU#max_number_of_cpu'
        rate.save
        rate2.dimension = 'CPU#average'
        rate2.save
        # Rating now should return the value
        expect(plan.calculate_total_cost(event)).to eq(Money.new(729))
      end
    end

    context 'rating with context' do
      let(:resource)      { FactoryGirl.create(:vm) }
      let(:event)         { FactoryGirl.build(:showback_event, :with_vm_data, :full_month, :with_tags_in_context, resource: resource) }
      let(:fixed_rate)    { Money.new(11) }
      let(:variable_rate) { Money.new(7) }
      let(:dimension)     { 'CPU#average' }
      let(:dimension2)    { 'CPU#max_number_of_cpu' }
      let(:plan)  { FactoryGirl.create(:showback_price_plan) }
      let(:rate)  do
        FactoryGirl.build(:showback_rate,
                          :showback_price_plan => plan,
                          :fixed_rate          => fixed_rate,
                          :variable_rate       => variable_rate,
                          :dimension           => dimension)
      end
      let(:rate2) do
        FactoryGirl.build(:showback_rate,
                          :showback_price_plan => plan,
                          :fixed_rate          => fixed_rate,
                          :variable_rate       => variable_rate,
                          :dimension           => dimension2)
      end

      it 'calculates costs when rate is not found' do
        event.save
        event.reload
        # test that the event has the information we need in data
        expect(event.data['CPU']).not_to be_nil
        expect(event.data['CPU']['average']).not_to be_nil
        expect(event.data['CPU']['max_number_of_cpu']).not_to be_nil
        # Make rate category not found
        rate.category = 'not-found'
        rate.save
        expect(plan.calculate_total_cost(event)).to eq(Money.new(0))
      end

      it 'calculates costs with one rate' do
        event.save
        event.reload
        # test that the event has the information we need in data
        expect(event.data['CPU']).not_to be_nil
        expect(event.data['CPU']['average']).not_to be_nil
        expect(event.data['CPU']['max_number_of_cpu']).not_to be_nil
        rate.dimension = 'CPU#max_number_of_cpu'
        rate.save
        # Rating now should return the value
        expect(plan.calculate_total_cost(event)).to eq(fixed_rate + event.get_measure_value('CPU','max_number_of_cpu') * variable_rate )
      end

      it 'calculates costs when more than one rate applies' do
        event.save
        event.reload
        # test that the event has the information we need in data
        expect(event.data['CPU']).not_to be_nil
        expect(event.data['CPU']['average']).not_to be_nil
        expect(event.data['CPU']['max_number_of_cpu']).not_to be_nil
        rate.dimension = 'CPU#max_number_of_cpu'
        rate.save
        rate2.dimension = 'CPU#average'
        rate2.save
        # Rating now should return the value
        expect(plan.calculate_total_cost(event)).to eq(rate.fixed_rate + rate2.fixed_rate + event.get_measure_value('CPU','average')  * rate.variable_rate + event.get_measure_value('CPU','max_number_of_cpu')  * rate2.variable_rate)
      end

    end
  end

  context '.seed' do
    let(:expected_showback_price_plan_count) { 1 }
    let!(:resource) { FactoryGirl.create(:miq_enterprise, :name => 'Enterprise') }

    it 'empty table' do
      described_class.seed
      expect(described_class.count).to eq(expected_showback_price_plan_count)
    end

    it 'run twice' do
      described_class.seed
      described_class.seed
      expect(described_class.count).to eq(expected_showback_price_plan_count)
    end
  end
end