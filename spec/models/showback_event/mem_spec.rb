describe ManageIQ::Consumption::ShowbackEvent::MEM do
  let(:event) { FactoryGirl.build(:showback_event) }
  let(:con_event) { FactoryGirl.build(:showback_event) }
  context "memory in vm" do
    before(:each) do
      @vm_metrics = FactoryGirl.create(:vm, :hardware => FactoryGirl.create(:hardware, :cpu1x2, :memory_mb => 4096))
      @vm_metrics.memory_reserve = 1024
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
        @vm_metrics.metrics << FactoryGirl.create(
          :metric_vm_rt,
          :timestamp                  => t,
          :cpu_usage_rate_average     => v,
          # Multiply by a factor of 1000 to make it more realistic and enable testing virtual col v_pct_cpu_ready_delta_summation
          :cpu_ready_delta_summation  => v * 1000,
          :sys_uptime_absolute_latest => v
        )
      end
      event.resource   = @vm_metrics
      event.start_time = "2010-04-13T00:00:00Z"
      event.end_time   = "2010-04-14T00:00:00Z"
      measure          = FactoryGirl.build(:showback_usage_type)
      measure.save
      event.generate_data
    end

    it "Calculate MEM_total_mem" do
      #validate that if memory is the same stored the same
      expect(event.MEM_total_mem(4096)).to eq(4096)
      #validate taht if memory values is 0 stored the same
      expect(event.MEM_total_mem(0)).to eq(4096)
      #validate
      expect(event.MEM_total_mem(8492)).to eq(8492)
    end
  end

  context "memory in container" do
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
                                                                  :state_data      => {:total_mem => 1024})
      end
      measure = FactoryGirl.build(:showback_usage_type)
      measure.save
      event.generate_data
    end

    it "Calculate MEM_max_mem" do
      #Expect return 1024 and assign 1024 because max is 0
      expect(event.MEM_total_mem(1024)).to eq(1024)
      #Expect return 1024 because 1024 >= 1024
      expect(event.MEM_total_mem(0)).to eq(1024)
      #Expect return 2048  because 2048 > 1024
      expect(event.MEM_total_mem(2048)).to eq(2048)
    end
  end
end
