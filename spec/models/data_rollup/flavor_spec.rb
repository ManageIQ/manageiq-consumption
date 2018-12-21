describe ManageIQ::Showback::DataRollup::FLAVOR do
  let(:data_rollup) { FactoryBot.build(:data_rollup) }
  context "FLAVOR in vm" do
    before(:each) do
      ManageIQ::Showback::InputMeasure.seed
      @vm_metrics = FactoryBot.create(:vm, :hardware => FactoryBot.create(:hardware, :cpu1x2, :memory_mb => 4096))
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
        @vm_metrics.metrics << FactoryBot.create(:metric_vm_rt,
                                                  :timestamp                  => t,
                                                  :cpu_usage_rate_average     => v,
                                                  # Multiply by a factor of 1000 to make it more realistic and enable testing virtual col v_pct_cpu_ready_delta_summation
                                                  :cpu_ready_delta_summation  => v * 1000,
                                                  :sys_uptime_absolute_latest => v)
      end
      data_rollup.resource     = @vm_metrics
      data_rollup.start_time   = "2010-04-13T00:00:00Z"
      data_rollup.end_time     = "2010-04-14T00:00:00Z"
      group = FactoryBot.build(:input_measure)
      group.save
      data_rollup.generate_data
    end

    it "Calculate FLAVOR_number" do
      data_rollup.FLAVOR_cpu_reserved
      expect(data_rollup.data["FLAVOR"]).not_to be_empty
      expect(data_rollup.data["FLAVOR"].length).to eq(1)
      expect(data_rollup.data["FLAVOR"].values.first["cores"]).to eq([2, "cores"])
      data_rollup.resource.hardware = FactoryBot.create(:hardware, :cpu4x2, :memory_mb => 8192)
      data_rollup.FLAVOR_cpu_reserved
      expect(data_rollup.data["FLAVOR"].length).to eq(2)
      expect(data_rollup.data["FLAVOR"].values.first["cores"]).not_to eq(data_rollup.data["FLAVOR"].values.last["cores"])
      expect(data_rollup.data["FLAVOR"].values.last["cores"]).to eq([8, "cores"])
    end

    it "Calculate FLAVOR_memory_reserve" do
      data_rollup.FLAVOR_memory_reserved
      expect(data_rollup.data["FLAVOR"]).not_to be_empty
      expect(data_rollup.data["FLAVOR"].length).to eq(1)
      expect(data_rollup.data["FLAVOR"].values.first["memory"]).to eq([4096, "Mb"])
      data_rollup.resource.hardware = FactoryBot.create(:hardware, :cpu4x2, :memory_mb => 8192)
      data_rollup.FLAVOR_memory_reserved
      expect(data_rollup.data["FLAVOR"].length).to eq(2)
      expect(data_rollup.data["FLAVOR"].values.first["memory"]).not_to eq(data_rollup.data["FLAVOR"].values.last["memory"])
      expect(data_rollup.data["FLAVOR"].values.last["memory"]).to eq([8192, "Mb"])
    end

    it "Calculate FLAVOR_memory_reserve and number" do
      data_rollup.FLAVOR_memory_reserved
      expect(data_rollup.data["FLAVOR"]).not_to be_empty
      expect(data_rollup.data["FLAVOR"].length).to eq(1)
      expect(data_rollup.data["FLAVOR"].values.first["memory"]).to eq([4096, "Mb"])
      data_rollup.resource.hardware = FactoryBot.create(:hardware, :cpu4x2, :memory_mb => 8192)
      data_rollup.FLAVOR_memory_reserved
      expect(data_rollup.data["FLAVOR"].length).to eq(2)
      expect(data_rollup.data["FLAVOR"].values.first["memory"]).not_to eq(data_rollup.data["FLAVOR"].values.last["memory"])
      expect(data_rollup.data["FLAVOR"].values.last["memory"]).to eq([8192, "Mb"])
    end
  end

  context "FLAVOR methods" do
    it "update_value_flavor" do
      data_rollup.send(:update_value_flavor, "cores", "2")
      data_rollup.send(:update_value_flavor, "memory", "2048")
      expect(data_rollup.data["FLAVOR"].keys.length).to eq(1)
      expect(data_rollup.data["FLAVOR"].first.second.values.length).to eq(2)
    end
  end

  context "FLAVOR in container" do
    before(:each) do
      ManageIQ::Showback::InputMeasure.seed
      @con_metrics              = FactoryBot.create(:container)
      data_rollup.resource      = @con_metrics
      data_rollup.resource.type = "Container"
      data_rollup.start_time    = "2010-04-13T00:00:00Z"
      data_rollup.end_time      = "2010-04-14T00:00:00Z"
      Range.new(data_rollup.start_time, data_rollup.end_time, true).step_value(1.hour).each do |t|
        @con_metrics.vim_performance_states << FactoryBot.create(:vim_performance_state,
                                                                  :timestamp       => t,
                                                                  :image_tag_names => "environment/prod",
                                                                  :state_data      => {:numvcpus => 2, :total_mem => 4096})
      end
      group = FactoryBot.build(:input_measure)
      group.save
      data_rollup.generate_data
    end

    it "Calculate FLAVOR_number" do
      data_rollup.FLAVOR_cpu_reserved
      expect(data_rollup.data["FLAVOR"]).not_to be_empty
      expect(data_rollup.data["FLAVOR"].length).to eq(1)
      expect(data_rollup.data["FLAVOR"].values.first["cores"]).to eq([2, "cores"])
      data_rollup.resource.vim_performance_states << FactoryBot.create(:vim_performance_state,
                                                                        :timestamp       => "2016-04-13T00:00:00Z",
                                                                        :image_tag_names => "environment/prod",
                                                                        :state_data      => {:numvcpus => 8, :total_mem => 4096})
      data_rollup.FLAVOR_cpu_reserved
      expect(data_rollup.data["FLAVOR"].length).to eq(2)
      expect(data_rollup.data["FLAVOR"].values.first["cores"]).not_to eq(data_rollup.data["FLAVOR"].values.last["cores"])
      expect(data_rollup.data["FLAVOR"].values.last["cores"]).to eq([8, "cores"])
    end

    it "Calculate FLAVOR_memory_reserve" do
      data_rollup.FLAVOR_memory_reserved
      expect(data_rollup.data["FLAVOR"]).not_to be_empty
      expect(data_rollup.data["FLAVOR"].length).to eq(1)
      expect(data_rollup.data["FLAVOR"].values.first["memory"]).to eq([4096, "Mb"])
      data_rollup.resource.vim_performance_states << FactoryBot.create(:vim_performance_state,
                                                                        :timestamp       => "2016-04-13T00:00:00Z",
                                                                        :image_tag_names => "environment/prod",
                                                                        :state_data      => {:numvcpus => 8, :total_mem => 8192})
      data_rollup.FLAVOR_memory_reserved
      expect(data_rollup.data["FLAVOR"].length).to eq(2)
      expect(data_rollup.data["FLAVOR"].values.first["memory"]).not_to eq(data_rollup.data["FLAVOR"].values.last["memory"])
      expect(data_rollup.data["FLAVOR"].values.last["memory"]).to eq([8192, "Mb"])
    end
  end
end
