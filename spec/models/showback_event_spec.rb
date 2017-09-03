require 'spec_helper'
require 'money-rails/test_helpers'

describe ManageIQ::Consumption::ShowbackEvent do
  let(:showback_event) { FactoryGirl.build(:showback_event) }
  context "validations" do
    it "has a valid factory" do
      expect(showback_event).to be_valid
    end

    it "should ensure presence of start_time" do
      showback_event.start_time = nil
      showback_event.valid?
      expect(showback_event.errors[:start_time]).to include "can't be blank"
    end

    it "should ensure presence of end_time" do
      showback_event.end_time = nil
      showback_event.valid?
      expect(showback_event.errors[:end_time]).to include "can't be blank"
    end

    it "should fails start time is after of end time" do
      showback_event.start_time = 1.hour.ago
      showback_event.end_time = 4.hours.ago
      showback_event.valid?
      expect(showback_event.errors[:start_time]).to include "Start time should be before end time"
    end

    it "should valid if start time is equal to end time" do
      showback_event.start_time = 1.hour.ago
      showback_event.end_time = showback_event.start_time
      expect(showback_event).to be_valid
    end

    it "should ensure presence of resource" do
      showback_event.resource = nil
      expect(showback_event).not_to be_valid
    end

    it "should ensure resource exists" do
      vm = FactoryGirl.create(:vm)
      showback_event.resource = vm
      expect(showback_event).to be_valid
    end

    it 'should generate data' do
      showback_event.data = {}
      showback_event.resource = FactoryGirl.create(:vm)
      hash = {}
      ManageIQ::Consumption::ShowbackUsageType.seed
      data_units = ManageIQ::Consumption::ConsumptionManager.load_column_units
      ManageIQ::Consumption::ShowbackUsageType.all.each do |measure_type|
        next unless showback_event.resource.type.ends_with?(measure_type.category)
        hash[measure_type.measure] = {}
        measure_type.dimensions.each do |dim|
          hash[measure_type.measure][dim] = [0,data_units[dim.to_sym] || ""] unless measure_type.measure == "FLAVOR"
        end
      end
      showback_event.generate_data
      expect(showback_event.data).to eq(hash)
      expect(showback_event.data).not_to be_empty
      expect(showback_event.start_time).not_to eq("")
    end
  end

  context '#flavor functions' do
    it 'should return last flavor' do
      showback_event.data = {"FLAVOR"=> {
                      1501545600 => {"cores"=>4, "memory"=>16},
                      1501632000 => {"cores"=>8, "memory"=>32},
                      1501804800 => {"cores"=>4, "memory"=>16},
                      1501704800 => {"cores"=>16,"memory"=>64},
      }}

      expect(showback_event.get_last_flavor).to eq({"cores"=>4,"memory"=>16})
      expect(showback_event.get_key_flavor("cores")).to eq(4)
      expect(showback_event.get_key_flavor("memory")).to eq(16)
    end
  end

  context '#validate_format' do
    it 'passes validation with correct JSON data' do
      event = FactoryGirl.create(:showback_event)
      expect(event.validate_format).to be_nil
    end

    it 'fails validations with incorrect JSON data' do
      event = FactoryGirl.build(:showback_event, :data => ":-Invalid:\n-JSON")
      expect(event.validate_format).to be_nil
    end
  end

  context '#engine' do
    let(:vm)               { FactoryGirl.create(:vm) }
    let(:event)            { FactoryGirl.build(:showback_event, :full_month) }
    let(:vm_event)         { FactoryGirl.build(:showback_event, :with_vm_data, :first_half_month) }
    describe 'Basic' do
      it 'should return the object' do
        event.resource = vm
        expect(event.resource).to eq(vm)
      end
      it 'trait #full_month should have a valid factory' do
        myevent = FactoryGirl.build(:showback_event, :full_month)
        myevent.valid?
        expect(myevent).to be_valid
        expect(myevent.start_time).to eq(myevent.start_time.beginning_of_month)
        expect(myevent.end_time).to eq(myevent.end_time.end_of_month)
      end

      it 'trait #with_vm_data should have a valid factory' do
        myevent = FactoryGirl.build(:showback_event, :with_vm_data)
        myevent.valid?
        expect(myevent.data).to eq("CPU"=>{"average"=>[29.8571428571429, "percent"], "number"=>[2.0, "cores"], "max_number_of_cpu"=>[2, "cores"]}, "MEM"=>{"max_mem"=>[2048, "Mib"]}, "FLAVOR"=>{})
        expect(myevent).to be_valid
      end

      it 'trait #first_half_month should have a valid factory' do
        myevent = FactoryGirl.build(:showback_event, :first_half_month)
        myevent.valid?
        expect(myevent).to be_valid
        expect(myevent.start_time).to eq(myevent.start_time.beginning_of_month)
        expect(myevent.end_time).to eq(myevent.end_time.change(:day => 15).end_of_day)
      end

      it 'trait #with_vm_datra and full_month has a valid factory' do
        myevent = FactoryGirl.build(:showback_event, :with_vm_data, :full_month)
        myevent.valid?
        expect(myevent).to be_valid
        expect(myevent.start_time).to eq(myevent.start_time.beginning_of_month)
        expect(myevent.end_time).to eq(myevent.end_time.end_of_month)
        expect(myevent.data).to eq("CPU"=>{"average"=>[29.8571428571429, "percent"], "number"=>[2.0, "cores"], "max_number_of_cpu"=>[2, "cores"]}, "MEM"=>{"max_mem"=>[2048, "Mib"]}, "FLAVOR"=>{})
      end

      it 'trait #with_vm_datra and half_month has a valid factory' do
        myevent = FactoryGirl.build(:showback_event, :with_vm_data, :first_half_month)
        myevent.valid?
        expect(myevent).to be_valid
        expect(myevent.start_time).to eq(myevent.start_time.beginning_of_month)
        expect(myevent.end_time).to eq(myevent.end_time.change(:day => 15).end_of_day)
        expect(myevent.data).to eq("CPU"=>{"average"=>[29.8571428571429, "percent"], "number"=>[2.0, "cores"], "max_number_of_cpu"=>[2, "cores"]}, "MEM"=>{"max_mem"=>[2048, "Mib"]}, "FLAVOR"=>{})
      end
    end

    context 'update events' do
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
          @vm_metrics.metrics << FactoryGirl.create(
              :metric_vm_rt,
              :timestamp                  => t,
              :cpu_usage_rate_average     => v,
              # Multiply by a factor of 1000 to make it more realistic and enable testing virtual col v_pct_cpu_ready_delta_summation
              :cpu_ready_delta_summation  => v * 1000,
              :sys_uptime_absolute_latest => v
          )
        end
        event.resource     = @vm_metrics
        event.start_time   = "2010-04-13T00:00:00Z"
        event.end_time     = "2010-04-14T00:00:00Z"
        measure = FactoryGirl.build(:showback_usage_type)
        measure.save
      end

      it 'should return value of the measure with dimension' do
        event.data = {
            'CPU' => {
                'average' => [event.resource.metrics.for_time_range(event.start_time, event.end_time).average(:cpu_usage_rate_average),"percent"]
            }
        }
        expect(event.start_time.month).to eq(event.end_time.month)
        expect(event.get_measure('CPU', 'average')).to eq([event.resource.metrics.for_time_range(event.start_time, event.end_time).average(:cpu_usage_rate_average).to_s,"percent"])
      end

      it 'return nil if dimension is not found' do
        event.data = {
            'CPU' => {
                'average' => [event.resource.metrics.for_time_range(event.start_time, event.end_time).average(:cpu_usage_rate_average),"percent"]
            }
        }
        expect(event.get_measure('CPU', 'not there')).to be_nil
      end

      it 'return nil if category is not found' do
        event.data = {
            'CPU' => {
                'average' => [event.resource.metrics.for_time_range(event.start_time, event.end_time).average(:cpu_usage_rate_average),"percent"]
            }
        }
        expect(event.get_measure('not there', 'average')).to be_nil
      end

      it 'should return [value,unit]n' do
        event.data = {"CPU" => { "average" => [52.67, "percent" ]}}
        expect(event.get_measure('CPU', 'average')).to eq([52.67,"percent"])
      end

      it 'should return metrics time range' do
        expect(event.metrics_time_range("2010-04-14T20:00:00Z", "2010-04-15T22:00:00Z").count).to eq(4)
      end

      it 'should return 0 metrics if start time is nil' do
        expect(event.metrics_time_range(nil, "2010-04-14T21:00:00Z").count).to eq(0)
      end

      it 'should return metrics over time range' do
        expect(event.metrics_time_range("2010-04-14T22:00:00Z", nil).count).to eq(4)
      end

      it 'should return events of past month' do
        5.times { FactoryGirl.create(:showback_event, :full_month) }
        2.times { FactoryGirl.create(:showback_event, :start_time => DateTime.now.utc.beginning_of_month - 1.month, :end_time => DateTime.now.utc.end_of_month - 1.month) }
        expect(described_class.events_past_month.count).to eq(2)
      end

      it 'should return events of actual month' do
        5.times { FactoryGirl.create(:showback_event, :full_month) }
        2.times do
          FactoryGirl.create(:showback_event,
                             :start_time => DateTime.now.utc.beginning_of_month - 1.month,
                             :end_time   => DateTime.now.utc.end_of_month - 1.month)
        end
        expect(described_class.events_actual_month.count).to eq(5)
      end

      it 'should return events between months' do
        3.times do
          FactoryGirl.create(:showback_event,
                             :start_time => DateTime.now.utc.beginning_of_month.change(:month =>2),
                             :end_time   => DateTime.now.utc.end_of_month.change(:month =>2))
        end
        2.times do
          FactoryGirl.create(:showback_event,
                             :start_time => DateTime.now.utc.beginning_of_month.change(:month =>4),
                             :end_time   => DateTime.now.utc.end_of_month.change(:month =>4))
        end
        expect(described_class.events_between_month(1, 3).count).to eq(3)
        # events_between_month
      end

      it 'should return number of days between start_time and end_time' do
        event.start_time = "2010-04-10T00:00:00Z"
        event.end_time   = "2010-04-14T00:00:00Z"
        expect(event.event_days).to eq(4)
      end

      it 'should update data event with average metrics' do
        event.start_time = "2010-04-13T00:00:00Z"
        event.end_time   = "2010-04-14T22:52:30Z"
        event.data = {
          "CPU" => {
              "average" => [event.resource.metrics.for_time_range(event.start_time, event.end_time).average(:cpu_usage_rate_average),"percent"]
          }
        }
        new_average = (event.get_measure_value("CPU","average").to_d * event.event_days +
            event.resource.metrics.for_time_range(event.end_time, nil).average(:cpu_usage_rate_average)) / (event.event_days + 1)
        event.update_event
        expect(event.start_time.month).to eq(event.end_time.month)
        expect(event.data).to eq("CPU" => { "average" => [new_average, "percent" ]})
      end

      it 'should return the max number of cpu' do
        event.data = {
          "CPU" => { "max_number_of_cpu" => [1,"cores"] }
        }
        event.update_event
        expect(event.data).to eq("CPU" => { "max_number_of_cpu" => [@vm_metrics.cpu_total_cores, "cores"] })
        event.data = {
          "CPU" => { "max_number_of_cpu" => [3,"cores"] }
        }
        event.update_event
        expect(event.start_time.month).to eq(event.end_time.month)
        expect(event.get_measure("CPU","max_number_of_cpu")).to eq([3,"cores"])
      end
    end

    context 'assign event to pool' do
      it "Return nil if not pool" do
        vm = FactoryGirl.create(:vm, :hardware => FactoryGirl.create(:hardware, :cpu1x2, :memory_mb => 4096))
        pool = FactoryGirl.create(:showback_pool, :resource => FactoryGirl.create(:vm, :hardware => FactoryGirl.create(:hardware, :cpu1x2, :memory_mb => 4096)))
        expect(event.find_pool(vm)).to be_nil
      end

      it "Return the correct pool" do
        vm = FactoryGirl.create(:vm, :hardware => FactoryGirl.create(:hardware, :cpu1x2, :memory_mb => 4096))
        pool = FactoryGirl.create(:showback_pool, :resource => vm)
        expect(event.find_pool(vm)).to eq(pool)
      end

      it "Return parent of resource" do
        host = FactoryGirl.create(:host)
        vm = FactoryGirl.create(:vm, :host => host)
        expect(event.get_parent(vm, "Host")).to eq(host)
      end

      it "Should return nil if not parent" do
        host = FactoryGirl.create(:host)
        vm = FactoryGirl.create(:vm, :host => host)
        expect(event.get_parent(vm, "Cluster")).to be_nil
      end

      it "Should return nil if error" do
        host = FactoryGirl.create(:host)
        vm = FactoryGirl.create(:vm, :host => host)
        expect(event.get_parent(vm, "H3dt")).to be_nil
      end

      it "Should return value of CPU data" do
        event.data = {"CPU" => { "average" => [52.67, "percent" ]}}
        expect(event.get_measure_value('CPU','average')).to eq(52.67)
      end

      it "Should return unit of CPU data" do
        event.data = {"CPU" => { "average" => [52.67, "percent" ]}}
        expect(event.get_measure_unit('CPU','average')).to eq("percent")
      end

      it "Assign resource to pool" do
        vm = FactoryGirl.create(:vm)
        pool = FactoryGirl.create(:showback_pool, :resource => vm)
        event = FactoryGirl.create(:showback_event,
                                   :start_time => DateTime.now.utc.beginning_of_month,
                                   :end_time => DateTime.now.utc.beginning_of_month + 2.days,
                                   :resource => vm)

        expect(pool.showback_events.count).to eq(0)
        event.assign_resource
        expect(pool.showback_events.count).to eq(1)
        expect(pool.showback_events.include?(event)).to be_truthy
      end

      it "Assign container resource to pool" do
        con = FactoryGirl.create(:container)
        con.type = "Container"
        pool = FactoryGirl.create(:showback_pool, :resource => con)
        event = FactoryGirl.create(:showback_event,
                                   :start_time => DateTime.now.utc.beginning_of_month,
                                   :end_time => DateTime.now.utc.beginning_of_month + 2.days,
                                   :resource => con)

        expect(pool.showback_events.count).to eq(0)
        event.assign_resource
        expect(pool.showback_events.count).to eq(1)
        expect(pool.showback_events.include?(event)).to be_truthy
      end

      it "Assign resource to all relational pool" do
        host = FactoryGirl.create(:host)
        vm = FactoryGirl.create(:vm, :host => host)
        pool_vm = FactoryGirl.create(:showback_pool, :resource => vm)
        pool_host = FactoryGirl.create(:showback_pool, :resource => host)
        event = FactoryGirl.create(:showback_event,
                                   :start_time => DateTime.now.utc.beginning_of_month,
                                   :end_time => DateTime.now.utc.beginning_of_month + 2.days,
                                   :resource => vm)
        event.assign_resource
        expect(pool_vm.showback_events.include?(event)).to be_truthy
        expect(pool_host.showback_events.include?(event)).to be_truthy
      end

      it "Assgin a pool tag " do
        @file = StringIO.new("name,category,entry\nJD-C-T4.0.1.44,Environment,Test")
        vm = FactoryGirl.create(:vm, :name => "JD-C-T4.0.1.44")
        event = FactoryGirl.create(:showback_event,
                                   :start_time => DateTime.now.utc.beginning_of_month,
                                   :end_time => DateTime.now.utc.beginning_of_month + 2.days,
                                   :resource => vm)
        category = FactoryGirl.create(:classification, :name => 'environment', :description => 'Environment')
        entry = FactoryGirl.create(:classification, :parent_id => category.id, :name => 'test', :description => 'Test')
        pool_cat = FactoryGirl.create(:showback_pool, :resource => category.tag)
        pool_ent = FactoryGirl.create(:showback_pool, :resource => entry.tag)
        ci = ClassificationImport.upload(@file)
        ci.apply
        vm.reload
        event.collect_tags
        event.assign_by_tag
        expect(pool_ent.showback_events.include?(event)).to be_truthy
        expect(pool_cat.showback_events.include?(event)).to be_truthy
      end
    end

    context 'collect tags' do
      it "Set an empty tags in context" do
        vm = FactoryGirl.create(:vm)
        event = FactoryGirl.create(:showback_event,
                                   :start_time => DateTime.now.utc.beginning_of_month,
                                   :end_time => DateTime.now.utc.beginning_of_month + 2.days,
                                   :resource => vm)
        event.collect_tags
        expect(event.context).to eq({ "tag" => {}})
      end

      it "Set a tags in context" do
        @file = StringIO.new("name,category,entry\nJD-C-T4.0.1.44,Environment,Test")
        vm = FactoryGirl.create(:vm, :name => "JD-C-T4.0.1.44")
        event = FactoryGirl.create(:showback_event,
                                   :start_time => DateTime.now.utc.beginning_of_month,
                                   :end_time => DateTime.now.utc.beginning_of_month + 2.days,
                                   :resource => vm)
        category = FactoryGirl.create(:classification, :name => 'environment', :description => 'Environment')
        entry = FactoryGirl.create(:classification, :parent_id => category.id, :name => 'test', :description => 'Test')
        ci = ClassificationImport.upload(@file)
        ci.apply
        vm.reload
        event.collect_tags
        expect(event.context).to eq({"tag"=>{"environment"=>["test"]}})
      end
    end
  end
  context 'update charges' do
    let(:event_to_charge) { FactoryGirl.create(:showback_event) }
    let(:pool_of_event) { FactoryGirl.create(:showback_pool,
                                            :resource => event_to_charge.resource) }

    it "Call update charges" do
      event_to_charge.data = {"CPU"=>{"average"=>[29.8571428571429, "percent"], "number"=>[2.0, "cores"], "max_number_of_cpu"=>[2, "cores"]}, "MEM"=>{"max_mem"=>[2048, "Mib"]}, "FLAVOR"=>{}}
      event_to_charge.save
      charge_1 = FactoryGirl.create(:showback_charge,
                                    :showback_pool => pool_of_event,
                                    :showback_event => event_to_charge,
                                    :stored_data =>{Time.now.utc - 5.hours => event_to_charge.data})
      data_1 = charge_1.stored_data_last
      event_to_charge.data = {"CPU"=>{"average"=>[49.8571428571429, "percent"], "number"=>[4.0, "cores"], "max_number_of_cpu"=>[6, "cores"]}, "MEM"=>{"max_mem"=>[2048, "Mib"]}, "FLAVOR"=>{}}
      event_to_charge.save
      event_to_charge.update_charges
      charge_1.reload
      expect(charge_1.stored_data_last).not_to eq(data_1)
    end
  end
end