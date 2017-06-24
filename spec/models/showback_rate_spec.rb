require 'spec_helper'
require 'money-rails/test_helpers'

describe ManageIQ::Consumption::ShowbackRate do
  context "validations" do
    let(:showback_rate) { FactoryGirl.build(:showback_rate) }

    it "has a valid factory" do
      expect(showback_rate).to be_valid
    end

    it "is not valid with a nil fixed_rate" do
      showback_rate.fixed_rate_subunits = nil
      showback_rate.valid?
      expect(showback_rate.errors.details[:fixed_rate]).to include(:error => :not_a_number, :value => '')
    end

    it "is not valid with a nil variable_rate" do
      showback_rate.variable_rate_subunits = nil
      showback_rate.valid?
      expect(showback_rate.errors.details[:variable_rate]).to include(:error => :not_a_number, :value => '')
    end

    it "is  valid with a nil concept" do
      showback_rate.concept = nil
      showback_rate.valid?
      expect(showback_rate).to be_valid
    end

    it "is not valid with a nil calculation" do
      showback_rate.calculation = nil
      showback_rate.valid?
      expect(showback_rate.errors.details[:calculation]).to include(:error=>:blank)
    end

    it "is is valid with a nil concept" do
      showback_rate.concept = nil
      showback_rate.valid?
      expect(showback_rate).to be_valid
    end

    it "is not valid with a nil dimension" do
      showback_rate.dimension = nil
      showback_rate.valid?
      expect(showback_rate.errors.details[:dimension]).to include(:error=>:blank)
    end

    pending "is not valid with a nil screener" do
      showback_rate.screener = nil
      showback_rate.valid?
      expect(showback_rate.errors.details[:screener]).to include(:error=>:blank)
    end
    it "fixed_rate expected to be Money" do
      expect(FactoryGirl.create(:showback_rate, :fixed_rate => Money.new("2.5634525342534"))).to be_valid
      expect(described_class).to monetize(:fixed_rate)
    end

    it "variable_rate expected to be Money" do
      expect(FactoryGirl.create(:showback_rate, :variable_rate => Money.new("67.4525342534"))).to be_valid
      expect(described_class).to monetize(:variable_rate)
    end
  end

  describe 'event lasts the full month' do
    let(:showback_rate)     { FactoryGirl.build(:showback_rate) }
    let(:showback_event_fm) { FactoryGirl.build(:showback_event, :full_month) }

=begin
    context 'empty #context' do
      it 'should charge an event by occurrence' do
        showback_rate.calculation = 'occurrence'
        showback_rate.fixed_rate_subunits = Money.new(11)
        showback_rate.variable_rate_subunits = Money.new(7)
        expect(showback_rate.rate(3, showback_event_fm)[0]).to eq(Money.new(11))
        expect(showback_rate.rate(3, showback_event_fm)[1]).to eq(Money.new(7))
      end

      it 'should charge an event by duration' do
        showback_rate.calculation = 'duration'
        showback_rate.fixed_rate_subunits = Money.new(11)
        showback_rate.variable_rate_subunits = Money.new(7)
        expect(showback_rate.rate(3, showback_event_fm)[0]).to eq(Money.new(11))
        expect(showback_rate.rate(3, showback_event_fm)[1]).to eq(Money.new(21))
      end

      it 'should charge an event by quantity' do
        showback_rate.calculation = 'quantity'
        showback_rate.fixed_rate_subunits = Money.new(11)
        showback_rate.variable_rate_subunits = Money.new(7)
        expect(showback_rate.rate(3, showback_event_fm)[0]).to eq(Money.new(11))
        expect(showback_rate.rate(3, showback_event_fm)[1]).to eq(Money.new(21))
      end
    end

    context 'complex #context' do
      pending 'it should charge an event by occurrence'
      pending 'it should charge an event by duration'
      pending 'it should charge an event by quantity'
    end
=end
  end

  describe 'event lasts the first 15 days' do
    let(:showback_rate)     { FactoryGirl.build(:consumption_showback_rate) }
    let(:showback_event_hm) { FactoryGirl.build(:consumption_showback_event, :first_half_month) }
    let(:proration)         { showback_event_hm.time_span / showback_event_hm.month_duration }
=begin
    context 'empty #context' do
      it 'should charge an event by occurrence' do
        showback_rate.calculation = 'occurrence'
        showback_rate.fixed_rate_subunits = Money.new(11)
        showback_rate.variable_rate_subunits = Money.new(7)
        expect(showback_rate.rate(3, showback_event_hm)[0]).to eq(Money.new(11))
        expect(showback_rate.rate(3, showback_event_hm)[1]).to eq(Money.new(7 * proration))
      end

      it 'should charge an event by duration' do
        showback_rate.calculation = 'duration'
        showback_rate.fixed_rate_subunits = Money.new(11)
        showback_rate.variable_rate_subunits = Money.new(7)
        expect(showback_rate.rate(3, showback_event_hm)[0]).to eq(Money.new(11 * proration))
        expect(showback_rate.rate(3, showback_event_hm)[1]).to eq(Money.new(21 * proration))
      end

      it 'should charge an event by quantity' do
        showback_rate.calculation = 'quantity'
        showback_rate.fixed_rate_subunits = Money.new(11)
        showback_rate.variable_rate_subunits = Money.new(7)
        expect(showback_rate.rate(3, showback_event_hm)[0]).to eq(Money.new(11 * proration))
        expect(showback_rate.rate(3, showback_event_hm)[1]).to eq(Money.new(21))
      end
    end
=end

    context 'complex #context' do
      pending 'it should charge an event by occurrence'
      pending 'it should charge an event by duration'
      pending 'it should charge an event by quantity'
    end
  end
end