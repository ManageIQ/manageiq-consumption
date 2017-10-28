require 'spec_helper'
require 'money-rails/test_helpers'

RSpec.describe ManageIQ::Consumption::Tier, :type => :model do
  describe 'model validations' do
    let(:rate) { FactoryGirl.create(:rate) }
    let(:tier) { rate.tiers.first }

    it 'has a valid factory' do
      expect(tier).to be_valid
    end

    it 'returns a name' do
      expect(tier.name).to eq("#{rate.entity}:#{rate.group}:#{rate.field}:Tier:#{tier.tier_start_value}-#{tier.tier_end_value}")
    end

    it 'is not valid with a nil fixed_rate' do
      tier.fixed_rate_subunits = nil
      tier.valid?
      expect(tier.errors.details[:fixed_rate]).to include(:error => :not_a_number, :value => '')
    end

    it 'is not valid with a nil variable_rate' do
      rate
      tier.variable_rate_subunits = nil
      tier.valid?
      expect(tier.errors.details[:variable_rate]).to include(:error => :not_a_number, :value => '')
    end

    it 'has a Money fixed_rate' do
      expect(described_class).to monetize(:fixed_rate)
      tier.fixed_rate = Money.new(256_000_000, 'US8')
      expect(tier).to be_valid
      expect(tier.fixed_rate.exchange_to('USD').format).to eq('$2.56')
    end

    it 'has a Money variable_rate' do
      expect(described_class).to monetize(:variable_rate)
      tier.variable_rate = Money.new(675_000_000, 'US8')
      expect(tier).to be_valid
      expect(tier.variable_rate.exchange_to('USD').format).to eq('$6.75')
    end

    it '#fixed_rate_per_time included in VALID_INTERVAL_UNITS is valid' do
      ManageIQ::Consumption::TimeConverterHelper::VALID_INTERVAL_UNITS.each do |interval|
        tier.fixed_rate_per_time = interval
        tier.valid?
        expect(tier).to be_valid
      end
    end

    it '#fixed_rate_per_time not included in VALID_INTERVAL_UNITS is not valid' do
      tier.fixed_rate_per_time = 'bad_interval'
      tier.valid?
      expect(tier.errors.details[:fixed_rate_per_time]).to include(:error => :inclusion, :value => 'bad_interval')
    end

    it '#variable_rate_per_time included in VALID_INTERVAL_UNITS is valid' do
      ManageIQ::Consumption::TimeConverterHelper::VALID_INTERVAL_UNITS.each do |interval|
        tier.variable_rate_per_time = interval
        tier.valid?
        expect(tier).to be_valid
      end
    end

    it '#variable_rate_per_time not included in VALID_INTERVAL_UNITS is not valid' do
      tier.variable_rate_per_time = 'bad_interval'
      tier.valid?
      expect(tier.errors.details[:variable_rate_per_time]).to include(:error => :inclusion, :value => 'bad_interval')
    end

    it '#variable_rate_per_unit is valid with a non empty string' do
      tier.variable_rate_per_unit = 'Hz'
      tier.valid?
      expect(tier).to be_valid
    end

    it '#variable_rate_per_unit is valid with an empty string' do
      tier.variable_rate_per_unit = ''
      tier.valid?
      expect(tier).to be_valid
    end

    it '#variable_rate_per_unit is not valid when nil' do
      tier.variable_rate_per_unit = nil
      tier.valid?
      expect(tier.errors.details[:variable_rate_per_unit]).to include(:error => :exclusion, :value => nil)
    end

    context 'validate intervals' do
      it 'end_value is lower than start_value' do
        tier.tier_start_value = 15
        tier.tier_end_value = 10
        expect { tier.valid? }.to raise_error(RuntimeError, _("Start value of interval is greater than end value"))
      end
      it '#there is a showbackTier just defined with Float::INFINITY you cant add another in this interval' do
        st = FactoryGirl.build(:tier, :rate => tier.rate, :tier_start_value => 5, :tier_end_value => 10)
        expect { st.valid? }.to raise_error(RuntimeError, _("Interval or subinterval is in a tier with Infinity at the end"))
      end
      it '#there is a showbackTier with Infinity' do
        st = FactoryGirl.build(:tier, :rate => tier.rate, :tier_start_value => 5, :tier_end_value => Float::INFINITY)
        expect { st.valid? }.to raise_error(RuntimeError, _("Interval or subinterval is in a tier with Infinity at the end"))
      end
      it '#there is a showbackTier just defined in this interval' do
        tier.tier_start_value = 2
        tier.tier_end_value = 7
        tier.save
        st = FactoryGirl.build(:tier, :rate => tier.rate, :tier_start_value => 5, :tier_end_value => 10)
        expect { st.valid? }.to raise_error(RuntimeError, _("Interval or subinterval is in another tier"))
      end
    end
  end

  describe 'tier methods' do
    let(:rate) { FactoryGirl.create(:rate) }
    let(:tier) { rate.tiers.first }
    context 'interval methods' do
      it '#range return the range of tier_start_value and tier_end_value' do
        expect(tier.range).to eq(0..Float::INFINITY)
      end
      it '#includes? method' do
        tier.tier_start_value = 2
        tier.tier_end_value = 4
        expect(tier.includes?(3)).to be_truthy
        expect(tier.includes?(5)).to be_falsey
        tier.tier_end_value = Float::INFINITY
        expect(tier.includes?(500)).to be_truthy
        expect(tier.includes?(1)).to be_falsey
      end
      it '#set_range method' do
        tier.set_range(2, 4)
        expect(tier.range).to eq(2..4)
        tier.set_range(2, Float::INFINITY)
        expect(tier.range).to eq(2..Float::INFINITY)
      end
      it '#starts_with_zero? method' do
        tier.tier_start_value = 2
        expect(tier.starts_with_zero?).to be_falsey
        tier.tier_start_value = 0
        expect(tier.starts_with_zero?).to be_truthy
      end
      it '#ends_with_infinity?method' do
        expect(tier.ends_with_infinity?).to be_truthy
        tier.tier_end_value = 10
        expect(tier.ends_with_infinity?).to be_falsey
      end
      it '#free? method' do
        tier.fixed_rate = 0
        tier.variable_rate = 0
        expect(tier.free?).to be_truthy
        tier.fixed_rate = 10
        expect(tier.free?).to be_falsey
        tier.fixed_rate = 0
        tier.variable_rate = 10
        expect(tier.free?).to be_falsey
        tier.fixed_rate = 10
        tier.variable_rate = 10
        expect(tier.free?).to be_falsey
      end
      it 'to_float method' do
        tier.tier_start_value = 2
        tier.tier_end_value = Float::INFINITY
        expect(described_class.to_float(tier.tier_start_value)).to eq(2)
        expect(described_class.to_float(tier.tier_end_value)).to eq(Float::INFINITY)
      end
      it 'divide tier method' do
        expect(ManageIQ::Consumption::Tier.where(:rate => tier.rate).count).to eq(1)
        tier.divide_tier(5)
        tier.reload
        expect(ManageIQ::Consumption::Tier.to_float(tier.tier_end_value)).to eq(5)
        expect(ManageIQ::Consumption::Tier.where(:rate => tier.rate).count).to eq(2)
      end
    end
  end
end
