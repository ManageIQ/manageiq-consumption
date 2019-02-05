require 'spec_helper'
require 'money-rails/test_helpers'
module ManageIQ::Showback
  describe Rate do
    let(:time_current) { Time.parse('Tue, 05 Feb 2019 18:53:19 UTC +00:00').utc }

    before do
      Timecop.travel(time_current)
    end

    before(:each) do
      Timecop.travel(time_current)
      InputMeasure.seed
    end

    after do
      Timecop.return
    end

    describe 'model validations' do
      let(:rate) { FactoryBot.build(:rate) }

      it 'has a valid factory' do
        expect(rate).to be_valid
      end

      it 'has a tier after create' do
        sr = FactoryBot.create(:rate)
        expect(sr.tiers.count).to eq(1)
      end

      it 'returns name as entity + field' do
        entity = rate.entity
        field = rate.field
        group = rate.group
        expect(rate.name).to eq("#{entity}:#{group}:#{field}")
      end

      it 'is not valid with a nil calculation' do
        rate.calculation = nil
        rate.valid?
        expect(rate.errors.details[:calculation]).to include(:error=>:blank)
      end

      it 'calculation is valid when included in VALID_RATE_CALCULATIONS' do
        calculations = %w(occurrence duration quantity)
        expect(ManageIQ::Showback::Rate::VALID_RATE_CALCULATIONS).to eq(calculations)
        calculations.each do |calc|
          rate.calculation = calc
          expect(rate).to be_valid
        end
      end

      it 'calculation is not valid if it is not in VALID_RATE_CALCULATIONS' do
        rate.calculation = 'ERROR'
        expect(rate).not_to be_valid
        expect(rate.errors.details[:calculation]). to include(:error => :inclusion, :value => 'ERROR')
      end

      it 'is not valid with a nil entity' do
        rate.entity = nil
        rate.valid?
        expect(rate.errors.details[:entity]).to include(:error=>:blank)
      end

      it 'is not valid with a nil field' do
        rate.field = nil
        rate.valid?
        expect(rate.errors.details[:field]).to include(:error=>:blank)
      end

      it 'is valid with a nil concept' do
        rate.concept = nil
        rate.valid?
        expect(rate).to be_valid
      end

      it '#group is valid with a non empty string' do
        rate.group = 'Hz'
        rate.valid?
        expect(rate).to be_valid
      end

      it '#group is not valid when nil' do
        rate.group = nil
        rate.valid?
        expect(rate.errors.details[:group]).to include(:error => :blank)
      end

      it 'is valid with a JSON screener' do
        rate.screener = JSON.generate('tag' => { 'environment' => ['test'] })
        rate.valid?
        expect(rate).to be_valid
      end

      pending 'is not valid with a wronly formatted screener' do
        rate.screener = JSON.generate('tag' => { 'environment' => ['test'] })
        rate.valid?
        expect(rate).not_to be_valid
      end

      it 'is not valid with a nil screener' do
        rate.screener = nil
        rate.valid?
        expect(rate.errors.details[:screener]).to include(:error => :exclusion, :value => nil)
      end
    end

    describe 'when the data_rollup lasts for the full month and the rates too' do
      let(:fixed_rate)    { Money.new(11) }
      let(:variable_rate) { Money.new(7) }
      let(:rate) { FactoryBot.create(:rate, :CPU_number) }
      let(:tier) do
        tier = rate.tiers.first
        tier.fixed_rate    = fixed_rate
        tier.variable_rate = variable_rate
        tier.variable_rate_per_unit = "cores"
        tier.save
        tier
      end
      let(:data_rollup_fm) { FactoryBot.create(:data_rollup, :full_month, :with_vm_data) }

      context 'empty #context, default rate per_time and per_unit' do
        it 'should data_view an data_rollup by occurrence when data_rollup exists' do
          tier
          data_rollup_fm.reload
          rate.calculation = 'occurrence'
          expect(rate.rate(data_rollup_fm)).to eq(fixed_rate + variable_rate)
        end

        it 'should data_view an data_rollup by occurrence only the fixed rate when value is nil' do
          tier
          data_rollup_fm.reload
          rate.calculation = 'occurrence'
          data_rollup_fm.data = {} # There is no data for this rate in the data_rollup
          expect(rate.rate(data_rollup_fm)).to eq(fixed_rate)
        end

        it 'should data_view an data_rollup by duration' do
          tier
          data_rollup_fm.reload
          rate.calculation = 'duration'
          expect(rate.rate(data_rollup_fm)).to eq(Money.new(11 + 7 * 2))
        end

        it 'should data_view an data_rollup by quantity' do
          tier
          data_rollup_fm.reload
          rate.calculation = 'quantity'
          expect(rate.rate(data_rollup_fm)).to eq(Money.new(11 + 7 * 2))
        end
      end

      context 'minimum step' do
        let(:fixed_rate)    { Money.new(11) }
        let(:variable_rate) { Money.new(7) }
        let(:rate) { FactoryBot.create(:rate, :MEM_max_mem) }
        let(:tier) do
          tier = rate.tiers.first
          tier.fixed_rate    = fixed_rate
          tier.variable_rate = variable_rate
          tier.variable_rate_per_unit = "MiB"
          tier.save
          tier
        end
        let(:data_rollup_fm) { FactoryBot.create(:data_rollup, :full_month, :with_vm_data) }
        let(:data_rollup_hm) { FactoryBot.create(:data_rollup, :first_half_month, :with_vm_data) }

        it 'nil step should behave like no step' do
          data_rollup_fm.reload
          tier.step_unit = nil
          tier.step_value = nil
          tier.step_time_value = nil
          tier.step_time_unit = nil
          tier.save
          rate.calculation = 'duration'
          expect(rate.rate(data_rollup_fm)).to eq(Money.new(11 + 7 * 2048))
        end

        it 'basic unit step should behave like no step' do
          data_rollup_fm.reload
          tier.step_unit = 'b'
          tier.step_value = 1
          tier.step_time_value = nil
          tier.step_time_unit = nil
          tier.save
          rate.calculation = 'duration'
          expect(rate.rate(data_rollup_fm)).to eq(Money.new(11 + 7 * 2048))
        end

        it 'when input is 0 it works' do
          tier.step_unit = 'b'
          tier.step_value = 1
          tier.step_time_value = nil
          tier.step_time_unit = nil
          rate.calculation = 'duration'
          data_rollup_fm.data["MEM"]["max_mem"][0] = 0
          expect(rate.rate(data_rollup_fm)).to eq(Money.new(11))
        end

        it 'should work if step unit is a subunit of the tier' do
          data_rollup_fm.reload
          tier.step_unit = 'Gib'
          tier.step_value = 1
          tier.step_time_value = nil
          tier.step_time_unit = nil
          rate.calculation = 'duration'
          tier.save
          expect(rate.rate(data_rollup_fm)).to eq(Money.new(11 + 7 * 2048))

          tier.step_value = 4
          tier.step_unit = 'Gib'
          tier.save
          expect(rate.rate(data_rollup_fm)).to eq(Money.new(11 + 7 * 4096))

          # Modify the input data so the data is not a multiple
          data_rollup_fm.data["MEM"]["max_mem"][0] = 501
          data_rollup_fm.data["MEM"]["max_mem"][1] = 'MiB'

          tier.step_unit = 'MiB'
          tier.step_value = 384
          tier.save
          expect(rate.rate(data_rollup_fm)).to eq(Money.new(11 + 7 * 384 * 2))
        end

        pending 'step time moves half_month to full_month' do
          tier.step_unit = 'b'
          tier.step_value = 1
          tier.step_time_value = 1
          tier.step_time_unit = 'month'
          rate.calculation = 'duration'
          expect(rate.rate(data_rollup_hm)).to eq(rate.rate(data_rollup_fm))
        end

        pending 'step is not a subunit of the tier' do
          # Rate is using Vm:CPU:Number
          tier.step_unit = 'cores'
          tier.step_value = 1
          tier.step_time_value = nil
          tier.step_time_unit = nil
          rate.calculation = 'duration'
          expect(rate.rate(data_rollup_fm)).to eq(Money.new(11 + 7 * 2))
        end

        pending 'step is higher than the tier'
      end

      context 'empty #context, modified per_time' do
        it 'should data_view an data_rollup by occurrence' do
          data_rollup_fm.reload
          rate.calculation = 'occurrence'
          tier.fixed_rate_per_time    = 'daily'
          tier.variable_rate_per_time = 'daily'
          tier.save
          days_in_month = Time.days_in_month(Time.current.month)
          expect(rate.rate(data_rollup_fm)).to eq(Money.new(days_in_month * (11 + 7)))
        end

        it 'should data_view an data_rollup by duration' do
          tier
          data_rollup_fm.reload
          rate.calculation = 'duration'
          tier.fixed_rate_per_time    = 'daily'
          tier.variable_rate_per_time = 'daily'
          tier.save
          days_in_month = Time.days_in_month(Time.current.month)
          expect(rate.rate(data_rollup_fm)).to eq(Money.new(days_in_month * (11 + 7 * 2)))
        end

        it 'should data_view an data_rollup by quantity' do
          data_rollup_fm.reload
          rate.calculation = 'quantity'
          tier.fixed_rate_per_time    = 'daily'
          tier.variable_rate_per_time = 'daily'
          tier.save
          days_in_month = Time.days_in_month(Time.current.month)
          # Fixed is 11 per day, variable is 7 per CPU, data_rollup has average of 2 CPU
          expect(rate.rate(data_rollup_fm)).to eq(Money.new((days_in_month * 11) + (7 * 2)))
        end
      end

      context 'empty context, modified per unit' do
        it 'should data_view an data_rollup by duration' do
          data_rollup_fm.reload
          rate.calculation = 'duration'
          rate.field = 'max_mem'
          rate.group = 'MEM'
          tier.variable_rate_per_unit = 'b'
          tier.save
          expect(rate.rate(data_rollup_fm)).to eq(Money.new(11 + (2048 * 1024 * 1024 * 7)))
          tier.variable_rate_per_unit = 'Kib'
          tier.save
          expect(rate.rate(data_rollup_fm)).to eq(Money.new(11 + (2048 * 1024 * 7)))
        end

        pending 'should data_view an data_rollup by quantity'
      end

      context 'tiered on input value' do
        pending 'it should data_view an data_rollup by occurrence'
        pending 'it should data_view an data_rollup by duration'
        pending 'it should data_view an data_rollup by quantity'
      end

      context 'tiered on non-input value in #context' do
        pending 'it should data_view an data_rollup by occurrence'
        pending 'it should data_view an data_rollup by duration'
        pending 'it should data_view an data_rollup by quantity'
      end
    end

    describe 'more than 1  tier in the rate' do
      let(:fixed_rate)    { Money.new(11) }
      let(:variable_rate) { Money.new(7) }
      let(:rate) { FactoryBot.create(:rate, :CPU_number, :calculation => 'quantity') }
      let(:data_rollup_hm) { FactoryBot.create(:data_rollup, :first_half_month, :with_vm_data) }
      let(:tier) do
        tier = rate.tiers.first
        tier.fixed_rate = fixed_rate
        tier.tier_end_value = 3.0
        tier.step_unit = 'cores'
        tier.step_value = 1
        tier.variable_rate = variable_rate
        tier.variable_rate_per_unit = "cores"
        tier.save
        tier
      end
      let(:tier_second) do
        FactoryBot.create(:tier,
                           :rate                   => rate,
                           :tier_start_value       => 3.0,
                           :tier_end_value         => Float::INFINITY,
                           :step_value             => 1,
                           :step_unit              => 'cores',
                           :fixed_rate             => Money.new(15),
                           :variable_rate          => Money.new(10),
                           :variable_rate_per_unit => "cores")
      end
      context 'use only a single tier' do
        it 'should data_view an data_rollup by quantity with 1 tier with tiers_use_full_value' do
          data_rollup_hm.reload
          tier
          tier_second
          expect(rate.rate(data_rollup_hm)).to eq(Money.new(11 + 7 * 2))
          data_rollup_hm.data['CPU']['number'][0] = 4.0
          expect(rate.rate(data_rollup_hm)).to eq(Money.new(15 + 10 * 4))
        end
        it 'should data_view an data_rollup by quantity with 1 tier with not tiers_use_full_value' do
          data_rollup_hm.reload
          tier
          tier_second
          rate.tiers_use_full_value = false
          rate.tier_input_variable = 'cores'
          expect(rate.rate(data_rollup_hm)).to eq(Money.new(11 + 7 * (2 - 0)))
          data_rollup_hm.data['CPU']['number'][0] = 4.0
          expect(rate.rate(data_rollup_hm)).to eq(Money.new(15 + (10 * (4 - 3.0))))
        end
      end

      context 'with all tiers' do
        it 'should data_view an data_rollup by quantity with 2 tiers with tiers_use_full_value' do
          data_rollup_hm.reload
          tier
          tier_second
          rate.uses_single_tier = false
          data_rollup_hm.data['CPU']['number'][0] = 4.0
          expect(rate.rate(data_rollup_hm)).to eq(Money.new(11 + 7 * 4) + Money.new(15 + 10 * 4))
        end

        it 'should data_view an data_rollup by quantity with 2 tiers with not tiers_use_full_value' do
          data_rollup_hm.reload
          tier
          tier_second
          rate.uses_single_tier = false
          rate.tiers_use_full_value = false
          rate.tier_input_variable = 'cores'
          data_rollup_hm.data['CPU']['number'][0] = 4.0
          expect(rate.rate(data_rollup_hm)).to eq(Money.new(11 + 7 * (4 - 0)) + Money.new(15 + 10 * (4 - 3.0)))
        end
      end
    end
    describe 'data_rollup lasts the first 15 days and the rate is monthly' do
      let(:fixed_rate)    { Money.new(11) }
      let(:variable_rate) { Money.new(7) }
      let(:rate) { FactoryBot.create(:rate, :CPU_number) }
      let(:data_rollup_hm) { FactoryBot.create(:data_rollup, :first_half_month, :with_vm_data) }
      let(:proration) { data_rollup_hm.time_span.to_f / data_rollup_hm.month_duration }
      let(:tier) do
        tier = rate.tiers.first
        tier.fixed_rate    = fixed_rate
        tier.variable_rate = variable_rate
        tier.variable_rate_per_unit = "cores"
        tier.save
        tier
      end

      context 'empty #context' do
        it 'should data_view an data_rollup by occurrence' do
          tier
          rate.calculation = 'occurrence'
          expect(rate.rate(data_rollup_hm)).to eq(Money.new(11) + Money.new(7))
        end

        it 'should data_view an data_rollup by duration' do
          tier
          data_rollup_hm.reload
          rate.calculation = 'duration'
          expect(rate.rate(data_rollup_hm)).to eq(Money.new(11 + 7 * 2) * proration)
        end

        it 'should data_view an data_rollup by quantity' do
          data_rollup_hm.reload
          tier
          rate.calculation = 'quantity'
          # Fixed is 11 per day, variable is 7 per CPU, data_rollup has 2 CPU
          expect(rate.rate(data_rollup_hm)).to eq(Money.new(11 + 7 * 2))
        end
      end

      context 'empty #context, modified per_time' do
        it 'should data_view an data_rollup by occurrence' do
          data_rollup_hm.reload
          rate.calculation = 'occurrence'
          tier.fixed_rate_per_time = 'daily'
          tier.variable_rate_per_time = 'daily'
          tier.save
          days_in_month = Time.days_in_month(Time.current.month)
          expect(rate.rate(data_rollup_hm)).to eq(Money.new(days_in_month * (11 + 7)))
        end

        it 'should data_view an data_rollup by duration' do
          data_rollup_hm.reload
          rate.calculation = 'duration'
          tier.fixed_rate_per_time    = 'daily'
          tier.variable_rate_per_time = 'daily'
          tier.save
          days_in_month = Time.days_in_month(Time.current.month)
          expect(rate.rate(data_rollup_hm)).to eq(Money.new(days_in_month * proration * (11 + 7 * 2)))
        end

        it 'should data_view an data_rollup by quantity' do
          data_rollup_hm.reload
          rate.calculation = 'quantity'
          tier.fixed_rate_per_time    = 'daily'
          tier.variable_rate_per_time = 'daily'
          tier.save
          days_in_month = Time.days_in_month(Time.current.month)
          # Fixed is 11 per day, variable is 7 per CPU, data_rollup has 2 CPU
          expect(rate.rate(data_rollup_hm)).to eq(Money.new((days_in_month * 11) + (7 * 2)))
        end
      end

      context 'tiered on input value' do
        pending 'it should data_view an data_rollup by occurrence'
        pending 'it should data_view an data_rollup by duration'
        pending 'it should data_view an data_rollup by quantity'
      end

      context 'tiered on non-input value in #context' do
        pending 'it should data_view an data_rollup by occurrence'
        pending 'it should data_view an data_rollup by duration'
        pending 'it should data_view an data_rollup by quantity'
      end
    end

    describe 'data_rollup lasts 1 day for a weekly rate' do
      pending 'should data_view an data_rollup by occurrence'
      pending 'should data_view an data_rollup by duration'
      pending 'should data_view an data_rollup by quantity'
    end

    describe 'data_rollup lasts 1 week for a daily rate' do
      pending 'should data_view an data_rollup by occurrence'
      pending 'should data_view an data_rollup by duration'
      pending 'should data_view an data_rollup by quantity'
    end
  end
end
