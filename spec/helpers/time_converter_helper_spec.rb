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

RSpec.describe ManageIQ::Consumption::TimeConverterHelper, :type => :helper do
  let(:time_current) { Time.parse('Mon, 05 Nov 2018 18:39:38 UTC +00:00').utc }

  before do
    Timecop.travel(time_current)
  end

  after do
    Timecop.return
  end

  let(:constants) do
    [described_class::VALID_INTERVAL_UNITS]
  end
  context 'CONSTANTS' do
    it 'symbols should be constant' do
      constants.each do |x|
        expect(x).to be_frozen
      end
    end
  end

  context '#number of intervals on this month' do
    let(:time_values) { [0.seconds, 15.minutes, 45.minutes, 1.hour, 90.minutes, 5.hours, 1.day, 1.5.days, 1.week, 1.4.weeks, 1.month - 1.second] }

    it 'minutely' do
      interval = 'minutely'
      results = [1, 15, 45, 60, 90, 300, 24 * 60, 15 * 24 * 6, 7 * 24 * 60, 14 * 7 * 24 * 6, 24 * 60 * Time.days_in_month(Time.current.month)]
      expect(results.length).to eq(time_values.length)
      start_t = Time.current.beginning_of_month
      time_values.each_with_index do |x, y|
        end_t =  start_t + x
        next unless start_t.month == end_t.month
        conversion = described_class.number_of_intervals(
          :period   => end_t - start_t,
          :interval => interval
        )
        expect(conversion)
          .to eq(results[y]),
              "Expected with #{interval} for #{x} s to match #{results[y]}, start: #{start_t}, end: #{end_t}, got #{conversion}"
      end
    end

    it 'hourly' do
      interval = 'hourly'
      results = [1, 1, 1, 1, 2, 5, 24, 36, 168, 236, 24 * Time.days_in_month(Time.current.month)]
      expect(results.length).to eq(time_values.length)
      start_t = Time.current.beginning_of_month
      time_values.each_with_index do |x, y|
        end_t =  start_t + x
        next unless start_t.month == end_t.month
        conversion = described_class.number_of_intervals(
          :period   => end_t - start_t,
          :interval => interval
        )
        expect(conversion)
          .to eq(results[y]),
              "Expected with #{interval} for #{x} s to match #{results[y]}, start: #{start_t}, end: #{end_t}, got #{conversion}"
      end
    end

    it 'daily' do
      interval = 'daily'
      results = [1, 1, 1, 1, 1, 1, 1, 2, 7, 10, Time.days_in_month(Time.current.month)]
      expect(results.length).to eq(time_values.length)
      start_t = Time.current.beginning_of_month
      time_values.each_with_index do |x, y|
        end_t =  start_t + x
        next unless start_t.month == end_t.month
        conversion = described_class.number_of_intervals(
          :period   => end_t - start_t,
          :interval => interval
        )
        expect(conversion)
          .to eq(results[y]),
              "Expected with #{interval} for #{x} s to match #{results[y]}, start: #{start_t}, end: #{end_t}, got #{conversion}"
      end
    end

    it 'weekly' do
      interval = 'weekly'
      results = [1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 5, 4]
      time_values.push(28.days)
      expect(results.length).to eq(time_values.length)
      start_t = Time.current.beginning_of_month
      time_values.each_with_index do |x, y|
        end_t =  start_t + x
        next unless start_t.month == end_t.month
        conversion = described_class.number_of_intervals(
          :period   => end_t - start_t,
          :interval => interval
        )
        expect(conversion)
          .to eq(results[y]),
              "Expected with #{interval} for #{x} s to match #{results[y]}, start: #{start_t}, end: #{end_t}, got #{conversion}"
      end
    end

    it 'monthly' do
      interval = 'monthly'
      results = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
      expect(results.length).to eq(time_values.length)
      start_t = Time.current.beginning_of_month
      time_values.each_with_index do |x, y|
        end_t =  start_t + x
        next unless start_t.month == end_t.month
        conversion = described_class.number_of_intervals(
          :period   => end_t - start_t,
          :interval => interval
        )
        expect(conversion)
          .to eq(results[y]),
              "Expected with #{interval} for #{x} s to match #{results[y]}, start: #{start_t}, end: #{end_t}, got #{conversion}"
      end
    end

    it 'yearly' do
      interval = 'yearly'
      results = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
      expect(results.length).to eq(time_values.length)
      start_t = Time.current.beginning_of_month
      time_values.each_with_index do |x, y|
        end_t =  start_t + x
        next unless start_t.month == end_t.month
        conversion = described_class.number_of_intervals(
          :period   => end_t - start_t,
          :interval => interval
        )
        expect(conversion)
          .to eq(results[y]),
              "Expected with #{interval} for #{x} s to match #{results[y]}, start: #{start_t}, end: #{end_t}, got #{conversion}"
      end
    end
  end

  context 'calculating for a different month than current' do
    let(:time_values) { [0.seconds, 15.minutes, 45.minutes, 1.hour, 90.minutes, 5.hours, 1.day, 1.5.days, 1.week, 1.4.weeks, 28.days - 1.second] }

    it 'hourly' do
      time = Time.zone.local(2017, 2, 1, 0, 0, 1)
      interval = 'hourly'
      results = [1, 1, 1, 1, 2, 5, 24, 36, 168, 236, 28 * 24]
      expect(results.length).to eq(time_values.length)
      start_t = time.beginning_of_month
      time_values.each_with_index do |x, y|
        end_t =  start_t + x
        next unless start_t.month == end_t.month
        conversion = described_class.number_of_intervals(
          :period           => end_t - start_t,
          :interval         => interval,
          :calculation_date => time
        )
        expect(conversion)
          .to eq(results[y]),
              "Expected with #{interval} for #{x} s to match #{results[y]}, start: #{start_t}, end: #{end_t}, got #{conversion}"
      end
    end
  end

  context "calculating with given lenghts" do
    let(:time_values) { [0.seconds, 15.minutes, 45.minutes, 1.hour, 90.minutes, 5.hours, 1.day, 1.5.days, 1.week, 1.4.weeks, 28.days - 1.second] }

    it 'monthly' do
      interval = 'monthly'
      days_in_month = 7 # Just testing that it work with different numbers
      results = [1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 4]
      expect(results.length).to eq(time_values.length)
      start_t = Time.current.beginning_of_month
      time_values.each_with_index do |x, y|
        end_t =  start_t + x
        next unless start_t.month == end_t.month
        conversion = described_class.number_of_intervals(
          :period        => end_t - start_t,
          :interval      => interval,
          :days_in_month => days_in_month
        )
        expect(conversion)
          .to eq(results[y]),
              "Expected with #{interval} for #{x} s to match #{results[y]}, start: #{start_t}, end: #{end_t}, got #{conversion}"
      end
    end
  end
end
