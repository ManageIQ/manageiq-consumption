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

RSpec.describe ManageIQ::Consumption::TimeConverterHelper, type: :helper do
  let(:constants) {
    [ManageIQ::Consumption::TimeConverterHelper::VALID_INTERVAL_UNITS]
  }
  context 'CONSTANTS' do
    it 'symbols should be constant' do
      constants.each do |x|
        expect(x).to be_frozen
      end
    end
  end

  context '#number of intervals on this month' do
    let(:time_values) { [0.seconds, 15.minutes, 45.minutes, 1.hour, 90.minutes, 5.hours, 1.day, (1.5).days, 1.week, (1.4).weeks, 1.month] }

    it 'hourly' do
      interval = 'hourly'
      interval_duration = 1.hour
      start_t = Time.now.beginning_of_month
      time_values.each do |x|
        end_t =  start_t + x
        next unless start_t.month == end_t.month
        conversion = ManageIQ::Consumption::TimeConverterHelper.number_of_intervals(start_t, end_t, interval)
        expect(conversion)
          .to eq(x.seconds.div interval_duration),
              "Expected with #{interval} for #{x} s to match #{x.seconds.div interval_duration}, start: #{start_t}, end: #{end_t}, got #{conversion}"
      end
    end

    it 'daily' do
      interval = 'daily'
      interval_duration = 1.day
      start_t = Time.now.beginning_of_month
      time_values.each do |x|
        end_t =  start_t + x
        next unless start_t.month == end_t.month
        conversion = ManageIQ::Consumption::TimeConverterHelper.number_of_intervals(start_t, end_t, interval)
        expect(conversion)
          .to eq(x.seconds.div interval_duration),
              "Expected with #{interval} for #{x} s to match #{x.seconds.div interval_duration}, start: #{start_t}, end: #{end_t}, got #{conversion}"
      end
    end

    it 'weekly' do
      interval = 'weekly'
      interval_duration = 1.week
      start_t = Time.now.beginning_of_month
      time_values.each do |x|
        end_t =  start_t + x
        next unless start_t.month == end_t.month
        conversion = ManageIQ::Consumption::TimeConverterHelper.number_of_intervals(start_t, end_t, interval)
        expect(conversion)
            .to eq(x.seconds.div interval_duration),
                "Expected with #{interval} for #{x} s to match #{x.seconds.div interval_duration}, start: #{start_t}, end: #{end_t}, got #{conversion}"
      end
    end

    it 'monthly' do
      interval = 'monthly'
      interval_duration = 1.month
      start_t = Time.now.beginning_of_month
      time_values.each do |x|
        end_t =  start_t + x
        next unless start_t.month == end_t.month
        conversion = ManageIQ::Consumption::TimeConverterHelper.number_of_intervals(start_t, end_t, interval)
        expect(conversion)
            .to eq(x.seconds.div interval_duration),
                "Expected with #{interval} for #{x} s to match #{x.seconds.div interval_duration}, start: #{start_t}, end: #{end_t}, got #{conversion}"
      end
    end
  end
end
