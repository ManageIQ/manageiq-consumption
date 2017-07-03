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

RSpec.describe ManageIQ::Consumption::UnitsConverterHelper, type: :helper do
  let(:constants) {
    [ManageIQ::Consumption::UnitsConverterHelper::SYMBOLS,
     ManageIQ::Consumption::UnitsConverterHelper::SI_PREFIX,
     ManageIQ::Consumption::UnitsConverterHelper::BINARY_PREFIX]
  }
  context 'CONSTANTS' do
    it 'symbols should be constant' do
      constants.each do |x|
        expect(x).to be_frozen
      end
    end
  end

  context '#extract_prefix' do
    it 'SI symbol prefixes should be extracted' do
      ManageIQ::Consumption::UnitsConverterHelper::SYMBOLS.each do |sym|
        ManageIQ::Consumption::UnitsConverterHelper::SI_PREFIX.each do |pf|
          expect(ManageIQ::Consumption::UnitsConverterHelper.extract_prefix(pf[0].to_s + sym)).to eq(pf[0].to_s)
        end
      end
    end

    it 'BINARY symbol prefixes should be extracted' do
      ManageIQ::Consumption::UnitsConverterHelper::SYMBOLS.each do |sym|
        ManageIQ::Consumption::UnitsConverterHelper::BINARY_PREFIX.each do |pf|
          expect(ManageIQ::Consumption::UnitsConverterHelper.extract_prefix(pf[0].to_s + sym)).to eq(pf[0].to_s)
        end
      end
    end

    it 'not found prefixes should return the full unit' do
      expect(ManageIQ::Consumption::UnitsConverterHelper.extract_prefix("ERROR")).to eq("ERROR")
    end

    it 'nil unit returns empty string' do
      expect(ManageIQ::Consumption::UnitsConverterHelper.extract_prefix(nil)).to eq("")
    end
  end

  context '#distance' do
    it 'SI symbol returns distance to base unit' do
      ManageIQ::Consumption::UnitsConverterHelper::SI_PREFIX.each do |pf|
        expect(ManageIQ::Consumption::UnitsConverterHelper.distance(pf[0].to_s)).to eq(pf[1][:value])
      end
    end

    it 'BINARY symbol returns distance to base unit' do
      ManageIQ::Consumption::UnitsConverterHelper::BINARY_PREFIX.each do |pf|
        expect(ManageIQ::Consumption::UnitsConverterHelper.distance(pf[0].to_s, '', :BINARY_PREFIX)).to eq(pf[1][:value])
      end
    end

    it 'SI symbol returns distance between symbols' do
      origin = finish = ['', 'K', 'M']
      units = ManageIQ::Consumption::UnitsConverterHelper::SI_PREFIX
      origin.each do |x|
        finish.each do |y|
          expect(ManageIQ::Consumption::UnitsConverterHelper.distance(x, y)).
              to eq(units[x.to_sym][:value].to_r / units[y.to_sym][:value])
        end
      end
    end

    it 'BINARY symbol returns distance between symbols' do
      origin = finish = ['', 'Ki', 'Mi']
      units = ManageIQ::Consumption::UnitsConverterHelper::BINARY_PREFIX
      origin.each do |x|
        finish.each do |y|
          expect(ManageIQ::Consumption::UnitsConverterHelper.distance(x, y, 'BINARY_PREFIX')).
              to eq(units[x.to_sym][:value].to_r / units[y.to_sym][:value])
        end
      end
    end
  end
  context '#to_unit' do
    it 'SI symbol returns value in base unit' do
      expect(ManageIQ::Consumption::UnitsConverterHelper.to_unit(7)).
          to eq(7)
      expect(ManageIQ::Consumption::UnitsConverterHelper.to_unit(7, 'K')).
          to eq(7000)
    end

    it 'BINARY symbol returns value in base unit' do
      expect(ManageIQ::Consumption::UnitsConverterHelper.to_unit(7, 'Ki', '', 'BINARY_PREFIX')).
          to eq(7168)
    end

    it 'SI symbol returns value in destination unit' do
      expect(ManageIQ::Consumption::UnitsConverterHelper.to_unit(7, 'M', 'K')).
          to eq(7000)
    end

    it 'SI symbol returns value in destination unit' do
      expect(ManageIQ::Consumption::UnitsConverterHelper.to_unit(7, 'Pi', 'Ti', 'BINARY_PREFIX')).
          to eq(7168)
    end
  end
end
