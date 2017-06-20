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
end