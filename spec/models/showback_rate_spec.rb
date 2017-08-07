require 'spec_helper'
require 'money-rails/test_helpers'

describe ManageIQ::Consumption::ShowbackRate do
  before(:all) do
    ManageIQ::Consumption::ShowbackUsageType.seed
  end
  context 'validations' do
    let(:showback_rate) { FactoryGirl.build(:showback_rate) }

    it 'has a valid factory' do
      expect(showback_rate).to be_valid
    end

    it 'is not valid with a nil fixed_rate' do
      showback_rate.fixed_rate_subunits = nil
      showback_rate.valid?
      expect(showback_rate.errors.details[:fixed_rate]).to include(:error => :not_a_number, :value => '')
    end

    it 'is not valid with a nil variable_rate' do
      showback_rate.variable_rate_subunits = nil
      showback_rate.valid?
      expect(showback_rate.errors.details[:variable_rate]).to include(:error => :not_a_number, :value => '')
    end

    it 'is valid with a nil concept' do
      showback_rate.concept = nil
      showback_rate.valid?
      expect(showback_rate).to be_valid
    end

    it 'is not valid with a nil calculation' do
      showback_rate.calculation = nil
      showback_rate.valid?
      expect(showback_rate.errors.details[:calculation]).to include(:error=>:blank)
    end

    it 'calculation can be occurrence, duration, quantity' do
      states = %w(occurrence duration quantity)
      states.each do |calc|
        showback_rate.calculation = calc
        expect(showback_rate).to be_valid
      end
    end

    it 'it can not be different of states open, processing, close' do
      showback_rate.calculation = 'ERROR'
      expect(showback_rate).not_to be_valid
      expect(showback_rate.errors.details[:calculation]). to include({ :error => :inclusion, :value => 'ERROR' })
    end

    it 'is is valid with a nil concept' do
      showback_rate.concept = nil
      showback_rate.valid?
      expect(showback_rate).to be_valid
    end

    it 'is not valid with a nil dimension' do
      showback_rate.dimension = nil
      showback_rate.valid?
      expect(showback_rate.errors.details[:dimension]).to include(:error=>:blank)
    end

    it 'returns name as category + dimension' do
      category = showback_rate.category
      dimension = showback_rate.dimension
      expect(showback_rate.name).to eq("#{category}:#{dimension}")
    end

    pending 'has a JSON screener'
    pending 'is not valid with a nil screener' do
      showback_rate.screener = nil
      showback_rate.valid?
      expect(showback_rate.errors.details[:screener]).to include(:error=>:blank)
    end

    it 'has a Money fixed_rate' do
      expect(described_class).to monetize(:fixed_rate)
      ch = FactoryGirl.create(:showback_rate, :fixed_rate => Money.new(256, 'USD'))
      expect(ch).to be_valid
      expect(ch.fixed_rate.format).to eq("$2.56")
    end

    it 'has a Money variable_rate' do
      expect(described_class).to monetize(:variable_rate)
      ch = FactoryGirl.create(:showback_rate, :variable_rate => Money.new(675, 'USD'))
      expect(ch).to be_valid
      expect(ch.variable_rate.format).to eq("$6.75")
    end
  end

  describe 'when the event lasts for the full month' do
    let(:fixed_rate)    { Money.new(11) }
    let(:variable_rate) { Money.new(7) }
    let(:showback_rate)     { FactoryGirl.build(:showback_rate, :fixed_rate => fixed_rate, :variable_rate => variable_rate) }
    let(:showback_event_fm) { FactoryGirl.build(:showback_event, :full_month) }


    context 'empty #context' do
      it 'should charge an event by occurrence' do
        showback_rate.calculation = 'occurrence'
        expect(showback_rate.rate(3, showback_event_fm)).to eq(Money.new(11 + 7))
      end

      it 'should charge an event by duration' do
        showback_rate.calculation = 'duration'
        expect(showback_rate.rate(3, showback_event_fm)).to eq(Money.new(11 + 21))
      end

      it 'should charge an event by quantity' do
        showback_rate.calculation = 'quantity'
        expect(showback_rate.rate(3, showback_event_fm)).to eq(Money.new(11 + 21))
      end
    end

    context 'tiered on input value' do
      pending 'it should charge an event by occurrence'
      pending 'it should charge an event by duration'
      pending 'it should charge an event by quantity'
    end

    context 'tiered on non-input value in #context' do
      pending 'it should charge an event by occurrence'
      pending 'it should charge an event by duration'
      pending 'it should charge an event by quantity'
    end
  end

  describe 'event lasts the first 15 days' do
    let(:fixed_rate)    { Money.new(11) }
    let(:variable_rate) { Money.new(7) }
    let(:showback_rate)     { FactoryGirl.build(:showback_rate, :fixed_rate => fixed_rate, :variable_rate => variable_rate) }
    let(:showback_event_hm) { FactoryGirl.build(:showback_event, :first_half_month) }
    let(:proration)         { showback_event_hm.time_span / showback_event_hm.month_duration }

    context 'empty #context' do
      it 'should charge an event by occurrence' do
        showback_rate.calculation = 'occurrence'
        expect(showback_rate.rate(3, showback_event_hm)).to eq(Money.new(11) + Money.new(7 * proration))
      end

      it 'should charge an event by duration' do
        showback_rate.calculation = 'duration'
        expect(showback_rate.rate(3, showback_event_hm)).to eq(Money.new(11 * proration) + Money.new(21 * proration))
      end

      it 'should charge an event by quantity' do
        showback_rate.calculation = 'quantity'
        expect(showback_rate.rate(3, showback_event_hm)).to eq(Money.new(11 * proration) + Money.new(21))
      end
    end

    context 'tiered on input value' do
      pending 'it should charge an event by occurrence'
      pending 'it should charge an event by duration'
      pending 'it should charge an event by quantity'
    end

    context 'tiered on non-input value in #context' do
      pending 'it should charge an event by occurrence'
      pending 'it should charge an event by duration'
      pending 'it should charge an event by quantity'
    end
  end
end