require 'spec_helper'
require 'money-rails/test_helpers'

describe ManageIQ::Consumption::InputMeasure do
  before(:each) do
    ManageIQ::Consumption::InputMeasure.delete_all
  end

  context "validations" do
    let(:input_measure) { FactoryGirl.build(:input_measure) }
    let(:data_rollup) { FactoryGirl.build(:showback_data_rollup) }

    it "has a valid factory" do
      expect(input_measure).to be_valid
    end
    it "should ensure presence of entity" do
      input_measure.entity = nil
      expect(input_measure).not_to be_valid
    end

    it "should ensure presence of entity included in VALID_entity fail" do
      input_measure.entity = "region"
      expect(input_measure).to be_valid
    end

    it "should ensure presence of description" do
      input_measure.description = nil
      input_measure.valid?
      expect(input_measure.errors[:description]).to include "can't be blank"
    end

    it "should ensure presence of group measure" do
      input_measure.group = nil
      input_measure.valid?
      expect(input_measure.errors.messages[:group]).to include "can't be blank"
    end

    it "should invalidate incorrect group measure" do
      input_measure.group = "AA"
      expect(input_measure).to be_valid
    end

    it "should validate correct group measure" do
      input_measure.group = "CPU"
      expect(input_measure).to be_valid
    end

    it "should ensure presence of fields included in VALID_TYPES" do
      input_measure.fields = %w(average number)
      expect(input_measure).to be_valid
    end

    it 'should return entity::group' do
      expect(input_measure.name).to eq("Vm::CPU")
    end

    it 'should be a function to calculate this usage' do
      described_class.seed
      described_class.all.each do |usage|
        usage.fields.each do |dim|
          expect(data_rollup).to respond_to("#{usage.group}_#{dim}")
        end
      end
    end
  end

  context ".seed" do
    let(:expected_input_measure_count) { 28 }

    it "empty table" do
      described_class.seed
      expect(described_class.count).to eq(expected_input_measure_count)
    end

    it "run twice" do
      described_class.seed
      described_class.seed
      expect(described_class.count).to eq(expected_input_measure_count)
    end
  end
end
