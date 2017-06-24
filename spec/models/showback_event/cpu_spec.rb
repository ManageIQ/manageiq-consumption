describe ManageIQ::Consumption::ShowbackEvent::CPU do
  let(:event) { FactoryGirl.build(:showback_event) }
  let(:con_event) { FactoryGirl.build(:showback_event) }
  context "CPU in vm" do
    before(:each) do
      @vm_metrics = FactoryGirl.create(:vm, :hardware => FactoryGirl.create(:hardware, :cpu1x2, :memory_mb => 4096))
      cases = [
        "2010-04-13T20:52:30Z", 100.0,
        "2010-04-13T21:51:10Z", 1.0,
        "2010-04-14T21:51:30Z", 2.0,
        "2010-04-14T22:51:50Z", 4.0,
        "2010-04-14T22:52:10Z", 8.0,
        "2010-04-14T22:52:30Z", 15.0,
        "2010-04-15T23:52:30Z", 100.0,
      ]
      cases.each_slice(2) do |t, v|
        @vm_metrics.metrics << FactoryGirl.create(:metric_vm_rt,
                                                  :timestamp                  => t,
                                                  :cpu_usage_rate_average     => v,
                                                  # Multiply by a factor of 1000 to make it more realistic and enable testing virtual col v_pct_cpu_ready_delta_summation
                                                  :cpu_ready_delta_summation  => v * 1000,
                                                  :sys_uptime_absolute_latest => v)
      end
      event.resource     = @vm_metrics
      event.start_time   = "2010-04-13T00:00:00Z"
      event.end_time     = "2010-04-14T00:00:00Z"
      measure = FactoryGirl.build(:showback_usage_type)
      measure.save
      event.generate_data
    end

    it "Calculate CPU average" do
      event.instance_variable_set(:@metrics, event.resource.metrics)
      expect(event.CPU_average(50)).to eq(41.42857142857145)
    end

    it "Calculate CPU average with no metrics" do
      event.instance_variable_set(:@metrics, [])
      expect(event.CPU_average(50)).to eq(50)
    end

    it "Calculate CPU_number" do
      expect(event.CPU_number(2)).to eq(2)
    end

    it "Calculate CPU_max_number_of_cpu" do
      expect(event.CPU_max_number_of_cpu(3)).to eq(3)
    end
  end

  context "CPU in container" do
    before(:each) do
      @con_metrics        = FactoryGirl.create(:container)
      event.resource      = @con_metrics
      event.resource.type = "Container"
      event.start_time    = "2010-04-13T00:00:00Z"
      event.end_time      = "2010-04-14T00:00:00Z"
      Range.new(event.start_time, event.end_time, true).step_value(1.hour).each do |t|
        @con_metrics.vim_performance_states << FactoryGirl.create(:vim_performance_state,
                                                                  :timestamp       => t,
                                                                  :image_tag_names => "environment/prod",
                                                                  :state_data      => {:numvcpus => 2})
      end
      measure = FactoryGirl.build(:showback_usage_type)
      measure.save
      event.generate_data
    end

    it "Calculate CPU_max_number_of_cpu" do
      expect(event.CPU_max_number_of_cpu(3)).to eq(3)
      expect(event.CPU_max_number_of_cpu(1)).to eq(2)
    end
  end
end
