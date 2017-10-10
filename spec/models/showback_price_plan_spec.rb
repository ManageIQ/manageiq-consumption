require 'spec_helper'
require 'money-rails/test_helpers'

RSpec.describe ManageIQ::Consumption::ShowbackPricePlan, :type => :model do
  # We need to ShowbackUsageType list to know what measures we should be looking for
  before(:each) do
    ManageIQ::Consumption::ShowbackUsageType.seed
  end

  context 'basic tests' do
    let(:plan) { FactoryGirl.create(:showback_price_plan) }

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
      expect { FactoryGirl.create(:showback_rate, :showback_price_plan => plan) }.to change(plan.showback_rates, :count).from(0).to(1)
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
      let(:plan)  { FactoryGirl.create(:showback_price_plan) }
      let(:rate)  do
        FactoryGirl.create(:showback_rate,
                          :CPU_average,
                          :calculation         => 'occurrence',
                          :showback_price_plan => plan)
      end
      let(:showback_tier) {
        tier = rate.showback_tiers.first
        tier.fixed_rate = fixed_rate
        tier.variable_rate = variable_rate
        tier.variable_rate_per_unit = "percent"
        tier.save
        tier
      }
      let(:rate2) do
        FactoryGirl.create(:showback_rate,
                          :CPU_max_number_of_cpu,
                          :calculation         => 'duration',
                          :showback_price_plan => plan)
      end
      let(:showback_tier2) {
        tier = rate2.showback_tiers.first
        tier.fixed_rate = fixed_rate2
        tier.variable_rate = variable_rate2
        tier.variable_rate_per_unit = "cores"
        tier.save
        tier
      }

      it 'calculates costs when rate is not found' do
        event.save
        event.reload
        # Make rate category not found
        rate.category = 'not-found'
        rate.save
        expect(plan.calculate_total_cost(event)).to(eq(Money.new(0)))
      end

      it 'calculates list of costs when rate is not found and default event data' do
        rate.category = 'not-found'
        rate.save
        resource_type = event.resource.type
        data = event.data
        expect(plan.calculate_list_of_costs_input(resource_type: resource_type, data: data)).to eq(plan.calculate_list_of_costs(event))
      end

      it 'calculates costs when rate is not found and event data' do
        rate.category = 'not-found'
        rate.save
        resource_type = event.resource.type
        data = event.data
        start_time = event.start_time
        end_time = event.end_time
        context = event.context
        expect(plan.calculate_list_of_costs_input(resource_type: resource_type,
                                                  data: data,
                                                  context: context,
                                                  start_time: start_time,
                                                  end_time: end_time)).to eq(plan.calculate_list_of_costs(event))
        expect(plan.calculate_list_of_costs_input(resource_type: resource_type, data: data)).to eq(plan.calculate_list_of_costs(event))
      end

      it 'test that data is right' do
        event.save
        event.reload
        # test that the event has the information we need in data
        expect(event.data['CPU']).not_to be_nil
        expect(event.data['CPU']['average']).not_to be_nil
        expect(event.data['CPU']['max_number_of_cpu']).not_to be_nil
      end

      it 'calculates costs with one rate2' do
        showback_tier
        event.save
        event.reload
        rate.save
        # Rating now should return the value
        expect(plan.calculate_total_cost(event)).to eq(Money.new(18))
      end

      it 'calculates costs when more than one rate applies' do
        event.save
        event.reload
        rate.save
        rate2.save
        # Rating now should return the value
        expect(plan.calculate_total_cost(event)).to eq(rate.rate(event) + rate2.rate(event))
      end
    end

    context 'rating with context' do
      let(:resource)      { FactoryGirl.create(:vm) }
      let(:event)         { FactoryGirl.build(:showback_event, :with_vm_data, :full_month, :with_tags_in_context, :resource => resource) }
      let(:fixed_rate)    { Money.new(11) }
      let(:variable_rate) { Money.new(7) }
      let(:plan)  { FactoryGirl.create(:showback_price_plan) }
      let(:rate)  do
        FactoryGirl.build(:showback_rate,
                          :CPU_average,
                          :showback_price_plan => plan)
      end
      let(:showback_tier1) {rate.showback_tiers.first}
      let(:rate2) do
        FactoryGirl.build(:showback_rate,
                          :CPU_max_number_of_cpu,
                          :showback_price_plan => plan)
      end
      let(:showback_tier2) {rate2.showback_tiers.first}

      it 'test that data is right' do
        event.save
        event.reload
        # test that the event has the information we need in data
        expect(event.data['CPU']).not_to be_nil
        expect(event.data['CPU']['average']).not_to be_nil
        expect(event.data['CPU']['max_number_of_cpu']).not_to be_nil
      end

      it 'returns list of costs when no rate is found' do
        event.save
        event.reload
        # Make rate category not found
        rate.category = 'not-found'
        rate.save
        expect(plan.calculate_list_of_costs(event)).to be_empty
      end

      it 'calculates costs when rate is not found' do
        event.save
        event.reload
        # Make rate category not found
        rate.category = 'not-found'
        rate.save
        expect(plan.calculate_total_cost(event)).to eq(Money.new(0))
      end

      it 'calculates costs with one rate' do
        event.save
        event.reload
        rate2.save
        # Rating now should return the value
        expect(plan.calculate_total_cost(event)).to eq(rate2.rate(event))
      end

      it 'returns list of costs with one rate' do
        event.save
        event.reload
        rate2.save
        # Rating now should return the value
        expect(plan.calculate_list_of_costs(event)).to match_array([[rate2.rate(event), rate2]])
      end

      it 'calculates costs when more than one rate applies' do
        event.save
        event.reload
        rate.save
        rate2.save
        # Rating now should return the value
        expect(plan.calculate_total_cost(event)).to eq(rate.rate(event) + rate2.rate(event))
      end

      it 'return list of costs when more than one rate applies' do
        event.save
        event.reload
        rate.save
        rate2.save
        # Rating now should return the value
        expect(plan.calculate_list_of_costs(event)).to match_array([[rate.rate(event), rate], [rate2.rate(event), rate2]])
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
