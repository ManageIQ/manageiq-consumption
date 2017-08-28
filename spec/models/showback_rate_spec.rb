require 'spec_helper'
require 'money-rails/test_helpers'
module ManageIQ::Consumption
  describe ShowbackRate do
    before(:all) do
      ShowbackUsageType.seed
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

      it 'is not valid with a nil calculation' do
        showback_rate.calculation = nil
        showback_rate.valid?
        expect(showback_rate.errors.details[:calculation]).to include(:error=>:blank)
      end

      it 'calculation is valid when in occurrence, duration, quantity' do
        calculations = %w(occurrence duration quantity)
        expect(ManageIQ::Consumption::ShowbackRate::VALID_RATE_CALCULATIONS).to eq(calculations)
        calculations.each do |calc|
          showback_rate.calculation = calc
          expect(showback_rate).to be_valid
        end
      end

      it 'calculation is not valid if it is not occurrence, duration, quantity' do
        showback_rate.calculation = 'ERROR'
        expect(showback_rate).not_to be_valid
        expect(showback_rate.errors.details[:calculation]). to include(:error => :inclusion, :value => 'ERROR')
      end

      it 'is not valid with a nil category' do
        showback_rate.category = nil
        showback_rate.valid?
        expect(showback_rate.errors.details[:category]).to include(:error=>:blank)
      end

      it 'is not valid with a nil dimension' do
        showback_rate.dimension = nil
        showback_rate.valid?
        expect(showback_rate.errors.details[:dimension]).to include(:error=>:blank)
      end

      it 'is valid with a nil concept' do
        showback_rate.concept = nil
        showback_rate.valid?
        expect(showback_rate).to be_valid
      end

      it 'returns name as category + dimension' do
        category = showback_rate.category
        dimension = showback_rate.dimension
        expect(showback_rate.name).to eq("#{category}:#{dimension}")
      end

      it '#fixed_rate_per_time included in VALID_INTERVAL_UNITS is valid' do
        TimeConverterHelper::VALID_INTERVAL_UNITS.each do |interval|
          showback_rate.fixed_rate_per_time = interval
          showback_rate.valid?
          expect(showback_rate).to be_valid
        end
      end

      it '#fixed_rate_per_time not included in VALID_INTERVAL_UNITS is not valid' do
        showback_rate.fixed_rate_per_time = 'bad_interval'
        showback_rate.valid?
        expect(showback_rate.errors.details[:fixed_rate_per_time]).to include(:error => :inclusion, :value => 'bad_interval')
      end

      it '#fixed_rate_per_unit is valid with a non empty string' do
        showback_rate.fixed_rate_per_unit = 'Hz'
        showback_rate.valid?
        expect(showback_rate).to be_valid
      end

      it '#fixed_rate_per_unit is valid with an empty string' do
        showback_rate.fixed_rate_per_unit = ''
        showback_rate.valid?
        expect(showback_rate).to be_valid
      end

      it '#fixed_rate_per_unit is not valid when nil' do
        showback_rate.fixed_rate_per_unit = nil
        showback_rate.valid?
        expect(showback_rate.errors.details[:fixed_rate_per_unit]).to include(:error => :exclusion, :value => nil)
      end

      it '#variable_rate_per_time included in VALID_INTERVAL_UNITS is valid' do
        TimeConverterHelper::VALID_INTERVAL_UNITS.each do |interval|
          showback_rate.variable_rate_per_time = interval
          showback_rate.valid?
          expect(showback_rate).to be_valid
        end
      end

      it '#variable_rate_per_time not included in VALID_INTERVAL_UNITS is not valid' do
        showback_rate.variable_rate_per_time = 'bad_interval'
        showback_rate.valid?
        expect(showback_rate.errors.details[:variable_rate_per_time]).to include(:error => :inclusion, :value => 'bad_interval')
      end

      it '#variable_rate_per_unit is valid with a non empty string' do
        showback_rate.variable_rate_per_unit = 'Hz'
        showback_rate.valid?
        expect(showback_rate).to be_valid
      end

      it '#variable_rate_per_unit is valid with an empty string' do
        showback_rate.variable_rate_per_unit = ''
        showback_rate.valid?
        expect(showback_rate).to be_valid
      end

      it '#variable_rate_per_unit is not valid when nil' do
        showback_rate.variable_rate_per_unit = nil
        showback_rate.valid?
        expect(showback_rate.errors.details[:variable_rate_per_unit]).to include(:error => :exclusion, :value => nil)
      end

      it 'is valid with a JSON screener' do
        showback_rate.screener = JSON.generate({ 'tag' => { 'environment' => ['test'] } })
        showback_rate.valid?
        expect(showback_rate).to be_valid
      end

      pending 'is not valid with a wronly formatted screener' do
        showback_rate.screener = JSON.generate({ 'tag' => { 'environment' => ['test'] } })
        showback_rate.valid?
        expect(showback_rate).not_to be_valid
      end

      it 'is not valid with a nil screener' do
        showback_rate.screener = nil
        showback_rate.valid?
        expect(showback_rate.errors.details[:screener]).to include(:error => :exclusion, :value => nil)
      end
    end

    describe 'when the event lasts for the full month' do
      let(:fixed_rate)    { Money.new(11) }
      let(:variable_rate) { Money.new(7) }
      let(:showback_rate)     { FactoryGirl.build(:showback_rate, :fixed_rate => fixed_rate, :variable_rate => variable_rate) }
      let(:showback_event_fm) { FactoryGirl.build(:showback_event, :full_month) }

      context 'empty #context, default rate per_time and per_unit' do
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

      context 'empty #context, modified per_time' do
        it 'should charge an event by occurrence' do
          showback_rate.calculation = 'occurrence'
          showback_rate.fixed_rate_per_time    = 'daily'
          showback_rate.variable_rate_per_time = 'daily'
          days_in_month = Time.days_in_month(Time.current.month)
          expect(showback_rate.rate(3, showback_event_fm)).to eq(Money.new(days_in_month * (11 + 7)))
        end

        it 'should charge an event by duration' do
          showback_rate.calculation = 'duration'
          showback_rate.fixed_rate_per_time    = 'daily'
          showback_rate.variable_rate_per_time = 'daily'
          days_in_month = Time.days_in_month(Time.current.month)
          expect(showback_rate.rate(3, showback_event_fm)).to eq(Money.new(days_in_month * (11 + 21)))
        end

        it 'should charge an event by quantity' do
          showback_rate.calculation = 'quantity'
          showback_rate.fixed_rate_per_time    = 'daily'
          showback_rate.variable_rate_per_time = 'daily'
          days_in_month = Time.days_in_month(Time.current.month)
          expect(showback_rate.rate(3, showback_event_fm)).to eq(Money.new(days_in_month * (11 + 21)))
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
      let(:proration)         { showback_event_hm.time_span.to_f / showback_event_hm.month_duration }

      context 'empty #context' do
        it 'should charge an event by occurrence' do
          showback_rate.calculation = 'occurrence'
          expect(showback_rate.rate(3, showback_event_hm)).to eq(Money.new(11) + Money.new(7))
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

      context 'empty #context, modified per_time' do
        it 'should charge an event by occurrence' do
          showback_rate.calculation = 'occurrence'
          showback_rate.fixed_rate_per_time    = 'daily'
          showback_rate.variable_rate_per_time = 'daily'
          days_in_month = Time.days_in_month(Time.current.month)
          expect(showback_rate.rate(3, showback_event_hm)).to eq(Money.new(days_in_month * (11 + 7)))
        end

        it 'should charge an event by duration' do
          showback_rate.calculation = 'duration'
          showback_rate.fixed_rate_per_time    = 'daily'
          showback_rate.variable_rate_per_time = 'daily'
          days_in_month = Time.days_in_month(Time.current.month)
          expect(showback_rate.rate(3, showback_event_hm)).to eq(Money.new(days_in_month * (11 * proration + 7 * 3 * proration)))
        end

        it 'should charge an event by quantity' do
          showback_rate.calculation = 'quantity'
          showback_rate.fixed_rate_per_time    = 'daily'
          showback_rate.variable_rate_per_time = 'daily'
          days_in_month = Time.days_in_month(Time.current.month)
          expect(showback_rate.rate(3, showback_event_hm)).to eq(Money.new(days_in_month * (11 * proration + 7 * 3)))
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
end
