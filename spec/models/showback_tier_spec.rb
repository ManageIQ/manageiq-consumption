require 'spec_helper'
require 'money-rails/test_helpers'

RSpec.describe ManageIQ::Consumption::ShowbackTier, :type => :model do
  describe 'model validations' do
    let(:showback_tier) { FactoryGirl.build(:showback_tier) }

    it 'has a valid factory' do
      expect(showback_tier).to be_valid
    end

    it 'is not valid with a nil fixed_rate' do
      showback_tier.fixed_rate_subunits = nil
      showback_tier.valid?
      expect(showback_tier.errors.details[:fixed_rate]).to include(:error => :not_a_number, :value => '')
    end

    it 'is not valid with a nil variable_rate' do
      showback_tier.variable_rate_subunits = nil
      showback_tier.valid?
      expect(showback_tier.errors.details[:variable_rate]).to include(:error => :not_a_number, :value => '')
    end

    it 'has a Money fixed_rate' do
      expect(described_class).to monetize(:fixed_rate)
      ch = FactoryGirl.create(:showback_tier, :fixed_rate => Money.new(256, 'USD'))
      expect(ch).to be_valid
      expect(ch.fixed_rate.format).to eq('$2.56')
    end

    it 'has a Money variable_rate' do
      expect(described_class).to monetize(:variable_rate)
      ch = FactoryGirl.create(:showback_tier, :variable_rate => Money.new(675, 'USD'))
      expect(ch).to be_valid
      expect(ch.variable_rate.format).to eq('$6.75')
    end

    it '#fixed_rate_per_time included in VALID_INTERVAL_UNITS is valid' do
      ManageIQ::Consumption::TimeConverterHelper::VALID_INTERVAL_UNITS.each do |interval|
        showback_tier.fixed_rate_per_time = interval
        showback_tier.valid?
        expect(showback_tier).to be_valid
      end
    end

    it '#fixed_rate_per_time not included in VALID_INTERVAL_UNITS is not valid' do
      showback_tier.fixed_rate_per_time = 'bad_interval'
      showback_tier.valid?
      expect(showback_tier.errors.details[:fixed_rate_per_time]).to include(:error => :inclusion, :value => 'bad_interval')
    end

    it '#variable_rate_per_time included in VALID_INTERVAL_UNITS is valid' do
      ManageIQ::Consumption::TimeConverterHelper::VALID_INTERVAL_UNITS.each do |interval|
        showback_tier.variable_rate_per_time = interval
        showback_tier.valid?
        expect(showback_tier).to be_valid
      end
    end

    it '#variable_rate_per_time not included in VALID_INTERVAL_UNITS is not valid' do
      showback_tier.variable_rate_per_time = 'bad_interval'
      showback_tier.valid?
      expect(showback_tier.errors.details[:variable_rate_per_time]).to include(:error => :inclusion, :value => 'bad_interval')
    end

    it '#variable_rate_per_unit is valid with a non empty string' do
      showback_tier.variable_rate_per_unit = 'Hz'
      showback_tier.valid?
      expect(showback_tier).to be_valid
    end

    it '#variable_rate_per_unit is valid with an empty string' do
      showback_tier.variable_rate_per_unit = ''
      showback_tier.valid?
      expect(showback_tier).to be_valid
    end

    it '#variable_rate_per_unit is not valid when nil' do
      showback_tier.variable_rate_per_unit = nil
      showback_tier.valid?
      expect(showback_tier.errors.details[:variable_rate_per_unit]).to include(:error => :exclusion, :value => nil)
    end
  end
end