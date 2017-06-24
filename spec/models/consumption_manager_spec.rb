require 'spec_helper'
require 'money-rails/test_helpers'

RSpec.describe ManageIQ::Consumption::ConsumptionManager, :type => :model do

  it ".name" do
    expect(described_class.name).to eq('Consumption')
  end

  it ".ems_type" do
    expect(described_class.ems_type).to eq('consumption_manager')
  end

  it ".description" do
    expect(described_class.description).to eq('Consumption Manager')
  end

  it "generate new month for actual events" do
    vm = FactoryGirl.create(:vm, :hardware => FactoryGirl.create(:hardware, :cpu1x2, :memory_mb => 4096))
    FactoryGirl.create(:showback_event,
                       :start_time    => DateTime.now.utc.beginning_of_month - 1.months,
                       :end_time      => DateTime.now.utc.end_of_month - 1.months,
                       :resource      =>vm)
    expect(ManageIQ::Consumption::ShowbackEvent.where(:resource =>vm).count).to eq(1)
    described_class.generate_new_month
    expect(ManageIQ::Consumption::ShowbackEvent.where(:resource =>vm).count).to eq(2)
  end

  it "should generate events for new resources" do
    vm = FactoryGirl.create(:vm)
    expect(ManageIQ::Consumption::ShowbackEvent.all.count).to eq(0)
    described_class.generate_events
    expect(ManageIQ::Consumption::ShowbackEvent.all.count).to eq(1)
    expect(ManageIQ::Consumption::ShowbackEvent.first.start_time.month).to eq(ManageIQ::Consumption::ShowbackEvent.first.end_time.month)
  end

  it "should not generate the same ShowbackEvent 2 times of the same resource" do
    vm = FactoryGirl.create(:vm)
    described_class.generate_events
    described_class.generate_events
    expect(ManageIQ::Consumption::ShowbackEvent.all.count).to eq(1)
  end

  it "should generate new Showbackevent of resource if not has an event for actual month" do
    vm = FactoryGirl.create(:vm)
    FactoryGirl.create(:showback_event,
                       :start_time    => DateTime.now.utc.beginning_of_month - 1.months,
                       :end_time      => DateTime.now.utc.end_of_month - 1.months,
                       :resource      => vm)
    count = ManageIQ::Consumption::ShowbackEvent.all.count
    described_class.generate_events
    expect(ManageIQ::Consumption::ShowbackEvent.all.count).to eq(count + 1)
  end

  it "should generate a showbackevent of service" do
    serv = FactoryGirl.create(:service)
    described_class.generate_events
    expect(ManageIQ::Consumption::ShowbackEvent.first.resource).to eq(serv)
    expect(ManageIQ::Consumption::ShowbackEvent.first.context).not_to be_nil
  end

  it "should update the events" do
    event_metric = FactoryGirl.create(:showback_event,:start_time => DateTime.now.utc.beginning_of_month, :end_time => DateTime.now.utc.beginning_of_month + 2.days)
    event_metric.data = {
        "CPU" => { "average" => 52.67, "max_number_of_cpu" => 4 }
    }
    data_new = {
        "CPU" => { "average" => 52.67, "max_number_of_cpu" => 4 }
    }
    @vm_metrics = FactoryGirl.create(:vm, :hardware => FactoryGirl.create(:hardware, :cpu1x2, :memory_mb => 4096))
    cases = [
        DateTime.now.utc.beginning_of_month , 100.0,
        DateTime.now.utc.beginning_of_month + 1.hours, 1.0,
        DateTime.now.utc.beginning_of_month + 3.days, 2.0,
        DateTime.now.utc.beginning_of_month + 4.days, 4.0,
        DateTime.now.utc.beginning_of_month + 5.days, 8.0,
        DateTime.now.utc.beginning_of_month + 6.days, 15.0,
        DateTime.now.utc.beginning_of_month + 7.days, 100.0,
    ]
    cases.each_slice(2) do |t, v|
      @vm_metrics.metrics << FactoryGirl.create(
          :metric_vm_rt,
          :timestamp                  => t,
          :cpu_usage_rate_average     => v,
          # Multiply by a factor of 1000 to make it more realistic and enable testing virtual col v_pct_cpu_ready_delta_summation
          :cpu_ready_delta_summation  => v * 1000,
          :sys_uptime_absolute_latest => v
      )
    end
    event_metric.resource_id = @vm_metrics.id
    event_metric.resource_type = @vm_metrics.class.name
    event_metric.save!
    new_average = (event_metric.data["CPU"]["average"].to_d * event_metric.event_days +
        event_metric.resource.metrics.for_time_range(event_metric.end_time, nil).average(:cpu_usage_rate_average)) / (event_metric.event_days + 1)
    data_new["CPU"]["average"] = new_average.to_s
    described_class.update_events
    event_metric.reload
    expect(event_metric.data).to eq(data_new)
    expect(event_metric.end_time).to eq(@vm_metrics.metrics.last.timestamp)
  end
end