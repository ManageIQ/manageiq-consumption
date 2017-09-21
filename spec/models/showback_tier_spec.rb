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
      showback_tier.fixed_rate = Money.new(256_000_000, 'US8'
      expect(showback_tier).to be_valid
      expect(showback_tier.fixed_rate.format).to eq('$2.56')
    end

    it 'has a Money variable_rate' do
      expect(described_class).to monetize(:variable_rate)
      showback_tier.variable_rate = Money.new(675_000_000, 'US8')
      expect(showback_tier).to be_valid
      expect(showback_tier.variable_rate.format).to eq('$6.75')
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
      let(:showback_rate){FactoryGirl.create(:showback_rate)}
      let(:showback_t1){FactoryGirl.create(:showback_tier, :showback_rate => showback_rate)}
      let(:showback_t2){FactoryGirl.build(:showback_tier, :showback_rate => showback_rate)}

      it '#there is a showbackTier just defined with Float::INFINITY you can add another in this interval' do
        showback_t2.tier_start_value = 5
        showback_t2.tier_end_value = 10
        expect { showback_t2.save }.to raise_error(RuntimeError, _("Interval or subinterval is in a tier with Infinity at the end"))
      end

=begin
      it '#there is a showbackTier just defined in this interval' do
        showback_t1.tier_start_value = 2
        showback_t1.tier_end_value = 7
        puts "1"
        showback_t1.save
        puts "2"
        showback_t2.tier_start_value = 5
        showback_t2.tier_end_value = 10
        puts showback_t1.inspect
        expect { showback_t2.save }.to raise_error(RuntimeError, _("Interval or subinterval is in another tier"))
      end
=end
    end

  end

  describe 'tier methods' do
    context 'interval methods' do
      let(:showback_tier){FactoryGirl.build(:showback_tier)}
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
        expect(showback_tier.free?).to be_falsey
        showback_tier.fixed_rate = 0
        expect(showback_tier.free?).to be_falsey
        showback_tier.fixed_rate = 10
        showback_tier.variable_rate = 0
        expect(showback_tier.free?).to be_falsey
        showback_tier.fixed_rate = 0
        expect(showback_tier.free?).to be_truthy
      end

      it 'to_float method' do
        showback_tier.tier_start_value = 2
        showback_tier.tier_end_value = Float::INFINITY
        expect(described_class.to_float(showback_tier.tier_start_value)).to eq(2)
        expect(described_class.to_float(showback_tier.tier_end_value)).to eq(Float::INFINITY)
      end

=begin
      it 'set_range method' do
        sb = FactoryGirl.build(:showback_tier)
        sb.set_range(5,7)
        expect(sb.range).to eq(5..7)
      end
=end
    end
  end


end