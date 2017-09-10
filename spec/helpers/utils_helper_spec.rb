require 'spec_helper'
# Specs in this file have access to a helper object that includes
# the UnitsConverterHelper. For example:
#
# describe ApplicationHelper do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       expect(helper.concat_strings("this","that")).to eq("this that")
#     end
#   end
# end

RSpec.describe ManageIQ::Consumption::UtilsHelper, type: :helper do
  let(:json_1) { JSON.parse '{ "tag": { "uno": 1, "dos": 2, "tres": 3, "cuatro": { "cinco": 5, "seis": 6} } }' }
  let(:json_2) { JSON.parse '{ "tag": { "cuatro": { "cinco": 5, "seis": 6 } } }' }
  let(:json_3) { JSON.parse '{ "cuatro": { "cinco": 5, "seis": 6, "siete": 7 } }' }
  let(:json_4) { JSON.parse '{ "siete": { "ocho": 8, "nueve": 9 } }' }

  context "#is_included_in?" do
    it "returns false if nil context or test" do
      expect(described_class.is_included_in?nil, "").to be false
      expect(described_class.is_included_in? "", nil).to be false
      expect(described_class.is_included_in? nil, nil).to be false
    end

    it "context and test are independent" do
      expect(described_class.is_included_in?json_1, json_4).to be false
    end

    it "context includes the test fully" do
      expect(described_class.is_included_in?json_1, json_2).to be true
    end

    it "content includes half of the test" do
      expect(described_class.is_included_in?json_1, json_3).to be false
    end

    it "content is empty" do
      expect(described_class.is_included_in?"", json_3).to be false
    end

    it "test is empty" do
      expect(described_class.is_included_in?json_1, "").to be true
    end

    it "contest and test are emtpy" do
      expect(described_class.is_included_in?json_1, "").to be true
    end
  end

  context "#get_parent" do
    it "Return parent of vm resource" do
      host = FactoryGirl.create(:host)
      vm = FactoryGirl.create(:vm, :host => host)
      expect(described_class.get_parent(vm)).to eq(host)
    end

    it "Should return nil if not parent vm" do
      vm = FactoryGirl.create(:vm)
      expect(described_class.get_parent(vm)).to be_nil
    end

    it "Should return nil if not parent container" do
      cont = FactoryGirl.create(:container)
      expect(described_class.get_parent(cont)).to be_nil
    end
  end
end
