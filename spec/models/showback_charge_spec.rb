require 'rails_helper'



RSpec.describe ManageIQ::Consumption::ShowbackCharge, :type => :model do
  let(:charge) { FactoryGirl.build(:showback_charge) }

  it 'has a valid factory' do
    expect(charge).to be_valid
  end

  it 'monetized cost' do
    expect(ManageIQ::Consumption::ShowbackCharge).to monetize(:cost)
    expect(charge).to monetize(:cost)
  end
end