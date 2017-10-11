require 'spec_helper'
require 'money-rails/test_helpers'

RSpec.describe ManageIQ::Consumption::ShowbackTier, :type => :model do
  describe 'model validations' do
    let(:showback_rate) { FactoryGirl.create(:showback_rate) }
    let(:showback_tier) { showback_rate.showback_tiers.first }

    it 'has a valid factory' do
      expect(showback_tier).to be_valid
    end

    it 'returns a name' do
      expect(showback_tier.name).to eq("#{showback_rate.category}:#{showback_rate.measure}:#{showback_rate.dimension}:Tier:#{showback_tier.tier_start_value}-#{showback_tier.tier_end_value}")
    end

    it 'is not valid with a nil fixed_rate' do
      showback_tier.fixed_rate_subunits = nil
      showback_tier.valid?
      expect(showback_tier.errors.details[:fixed_rate]).to include(:error => :not_a_number, :value => '')
    end

    it 'is not valid with a nil variable_rate' do
      showback_rate
      showback_tier.variable_rate_subunits = nil
      showback_tier.valid?
      expect(showback_tier.errors.details[:variable_rate]).to include(:error => :not_a_number, :value => '')
    end

    it 'has a Money fixed_rate' do
      expect(described_class).to monetize(:fixed_rate)
      showback_tier.fixed_rate = Money.new(256_000_000, 'US8')
      expect(showback_tier).to be_valid
      expect(showback_tier.fixed_rate.exchange_to('USD').format).to eq('$2.56')
    end

    it 'has a Money variable_rate' do
      expect(described_class).to monetize(:variable_rate)
      showback_tier.variable_rate = Money.new(675_000_000, 'US8')
      expect(showback_tier).to be_valid
      expect(showback_tier.variable_rate.exchange_to('USD').format).to eq('$6.75')
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

    context 'validate intervals' do
      it 'end_value is lower than start_value' do
        showback_tier.tier_start_value = 15
        showback_tier.tier_end_value = 10
        expect { showback_tier.valid? }.to raise_error(RuntimeError, _("Start value of interval is greater than end value"))
      end
      it '#there is a showbackTier just defined with Float::INFINITY you cant add another in this interval' do
        st = FactoryGirl.build(:showback_tier, :showback_rate => showback_tier.showback_rate, :tier_start_value => 5, :tier_end_value => 10)
        expect { st.valid? }.to raise_error(RuntimeError, _("Interval or subinterval is in a tier with Infinity at the end"))
      end
      it '#there is a showbackTier with Infinity' do
        st = FactoryGirl.build(:showback_tier, :showback_rate => showback_tier.showback_rate, :tier_start_value => 5, :tier_end_value => Float::INFINITY)
        expect { st.valid? }.to raise_error(RuntimeError, _("Interval or subinterval is in a tier with Infinity at the end"))
      end
      it '#there is a showbackTier just defined in this interval' do
        showback_tier.tier_start_value = 2
        showback_tier.tier_end_value = 7
        showback_tier.save
        st = FactoryGirl.build(:showback_tier, :showback_rate => showback_tier.showback_rate, :tier_start_value => 5, :tier_end_value => 10)
        expect { st.valid? }.to raise_error(RuntimeError, _("Interval or subinterval is in another tier"))
      end
    end
  end

  describe 'tier methods' do
    let(:showback_rate) { FactoryGirl.create(:showback_rate) }
    let(:showback_tier) { showback_rate.showback_tiers.first }
    context 'interval methods' do
      it '#range return the range of tier_start_value and tier_end_value' do
        expect(showback_tier.range).to eq(0..Float::INFINITY)
      end
      it '#includes? method' do
        showback_tier.tier_start_value = 2
        showback_tier.tier_end_value = 4
        expect(showback_tier.includes?(3)).to be_truthy
        expect(showback_tier.includes?(5)).to be_falsey
        showback_tier.tier_end_value = Float::INFINITY
        expect(showback_tier.includes?(500)).to be_truthy
        expect(showback_tier.includes?(1)).to be_falsey
      end
      it '#set_range method' do
        showback_tier.set_range(2, 4)
        expect(showback_tier.range).to eq(2..4)
        showback_tier.set_range(2, Float::INFINITY)
        expect(showback_tier.range).to eq(2..Float::INFINITY)
      end
      it '#starts_with_zero? method' do
        showback_tier.tier_start_value = 2
        expect(showback_tier.starts_with_zero?).to be_falsey
        showback_tier.tier_start_value = 0
        expect(showback_tier.starts_with_zero?).to be_truthy
      end
      it '#ends_with_infinity?method' do
        expect(showback_tier.ends_with_infinity?).to be_truthy
        showback_tier.tier_end_value = 10
        expect(showback_tier.ends_with_infinity?).to be_falsey
      end
      it '#free? method' do
        showback_tier.fixed_rate = 0
        showback_tier.variable_rate = 0
        expect(showback_tier.free?).to be_truthy
        showback_tier.fixed_rate = 10
        expect(showback_tier.free?).to be_falsey
        showback_tier.fixed_rate = 0
        showback_tier.variable_rate = 10
        expect(showback_tier.free?).to be_falsey
        showback_tier.fixed_rate = 10
        showback_tier.variable_rate = 10
        expect(showback_tier.free?).to be_falsey
      end
      it 'to_float method' do
        showback_tier.tier_start_value = 2
        showback_tier.tier_end_value = Float::INFINITY
        expect(described_class.to_float(showback_tier.tier_start_value)).to eq(2)
        expect(described_class.to_float(showback_tier.tier_end_value)).to eq(Float::INFINITY)
      end
      it 'divide tier method' do
        expect(ManageIQ::Consumption::ShowbackTier.where(:showback_rate => showback_tier.showback_rate).count).to eq(1)
        showback_tier.divide_tier(5)
        showback_tier.reload
        expect(ManageIQ::Consumption::ShowbackTier.to_float(showback_tier.tier_end_value)).to eq(5)
        expect(ManageIQ::Consumption::ShowbackTier.where(:showback_rate => showback_tier.showback_rate).count).to eq(2)
      end
    end
  end
end
