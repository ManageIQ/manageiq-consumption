require 'spec_helper'
require 'money-rails/test_helpers'

RSpec.describe ManageIQ::Consumption::ShowbackCharge, :type => :model do
  let(:charge) { FactoryGirl.build(:showback_charge) }

  it 'has a valid factory' do
    expect(charge).to be_valid
  end

  it 'monetizes cost' do
    expect(described_class).to monetize(:cost)
    expect(charge).to monetize(:cost)
  end

  it "clean costs" do
    ch = FactoryGirl.build(:showback_charge, :cost => Money.new(10))
    ch.clean_costs
    expect(ch.cost).to eq(Money.new(0))
  end

  it "calculate_costs" do
    ch = FactoryGirl.build(:showback_charge, :cost => Money.new(10))
    ch.calculate_costs(FactoryGirl.build(:showback_price_plan))
    expect(ch.cost).to eq(Money.new(10))
  end

  pending 'calculates cost'
  pending 'return costs'
end