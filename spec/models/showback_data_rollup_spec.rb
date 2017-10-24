require 'spec_helper'
require 'money-rails/test_helpers'

describe ManageIQ::Consumption::ShowbackDataRollup do
  let(:data_rollup) { FactoryGirl.build(:showback_data_rollup) }
  context "validations" do
    it "has a valid factory" do
      expect(data_rollup).to be_valid
    end

    it "should ensure presence of start_time" do
      data_rollup.start_time = nil
      data_rollup.valid?
      expect(data_rollup.errors[:start_time]).to include "can't be blank"
    end

    it "should ensure presence of end_time" do
      data_rollup.end_time = nil
      data_rollup.valid?
      expect(data_rollup.errors[:end_time]).to include "can't be blank"
    end

    it "should fails start time is after of end time" do
      data_rollup.start_time = 1.hour.ago
      data_rollup.end_time = 4.hours.ago
      data_rollup.valid?
      expect(data_rollup.errors[:start_time]).to include "Start time should be before end time"
    end

    it "should valid if start time is equal to end time" do
      data_rollup.start_time = 1.hour.ago
      data_rollup.end_time = data_rollup.start_time
      expect(data_rollup).to be_valid
    end

    it "should ensure presence of resource" do
      data_rollup.resource = nil
      expect(data_rollup).not_to be_valid
    end

    it "should ensure resource exists" do
      vm = FactoryGirl.create(:vm)
      data_rollup.resource = vm
      expect(data_rollup).to be_valid
    end

    it 'should generate data' do
      data_rollup.data = {}
      data_rollup.resource = FactoryGirl.create(:vm)
      hash = {}
      ManageIQ::Consumption::ShowbackInputMeasure.seed
      data_units = ManageIQ::Consumption::ConsumptionManager.load_column_units
      ManageIQ::Consumption::ShowbackInputMeasure.all.each do |group_type|
        next unless data_rollup.resource.type.ends_with?(group_type.entity)
        hash[group_type.group] = {}
        group_type.fields.each do |dim|
          hash[group_type.group][dim] = [0, data_units[dim.to_sym] || ""] unless group_type.group == "FLAVOR"
        end
      end
      data_rollup.generate_data
      expect(data_rollup.data).to eq(hash)
      expect(data_rollup.data).not_to be_empty
      expect(data_rollup.start_time).not_to eq("")
    end

    it "should clean data " do
      data_rollup.data = { "cores" => 2}
      expect(data_rollup.data).not_to be_empty
      data_rollup.clean_data
      expect(data_rollup.data).to be_empty
    end
  end

  context '#flavor functions' do
    it 'should return last flavor' do
      data_rollup.data = {
        "FLAVOR" => {
          1_501_545_600 => {"cores" => 4,  "memory" => 16},
          1_501_632_000 => {"cores" => 8,  "memory" => 32},
          1_501_804_800 => {"cores" => 4,  "memory" => 16},
          1_501_704_800 => {"cores" => 16, "memory" => 64},
        }
      }

      expect(data_rollup.last_flavor).to eq("cores" => 4, "memory" => 16)
      expect(data_rollup.get_key_flavor("cores")).to eq(4)
      expect(data_rollup.get_key_flavor("memory")).to eq(16)
    end
  end

  context '#validate_format' do
    it 'passes validation with correct JSON data' do
      event = FactoryGirl.create(:showback_data_rollup)
      expect(event.validate_format).to be_nil
    end

    it 'fails validations with incorrect JSON data' do
      event = FactoryGirl.build(:showback_data_rollup, :data => ":-Invalid:\n-JSON")
      expect(event.validate_format).to be_nil
    end

    it 'returns nil if ParserError' do
      event = FactoryGirl.create(:showback_data_rollup)
      event.data = "abc"
      expect(event.validate_format).to be_nil
    end
  end

  context '#engine' do
    let(:vm)               { FactoryGirl.create(:vm) }
    let(:event)            { FactoryGirl.build(:showback_data_rollup, :full_month) }
    let(:vm_event)         { FactoryGirl.build(:showback_data_rollup, :with_vm_data, :first_half_month) }
    describe 'Basic' do
      it 'should return the object' do
        event.resource = vm
        expect(event.resource).to eq(vm)
      end
      it 'trait #full_month should have a valid factory' do
        myevent = FactoryGirl.build(:showback_data_rollup, :full_month)
        myevent.valid?
        expect(myevent).to be_valid
        expect(myevent.start_time).to eq(myevent.start_time.beginning_of_month)
        expect(myevent.end_time).to eq(myevent.end_time.end_of_month)
      end

      it 'trait #with_vm_data should have a valid factory' do
        myevent = FactoryGirl.build(:showback_data_rollup, :with_vm_data)
        myevent.valid?
        expect(myevent.data).to eq(
          "CPU"    => {
            "average"           => [29.8571428571429, "percent"],
            "number"            => [2.0, "cores"],
            "max_number_of_cpu" => [2, "cores"]
          },
          "MEM"    => {
            "max_mem" => [2048, "Mib"]
          },
          "FLAVOR" => {}
        )
        expect(myevent).to be_valid
      end

      it 'trait #first_half_month should have a valid factory' do
        myevent = FactoryGirl.build(:showback_data_rollup, :first_half_month)
        myevent.valid?
        expect(myevent).to be_valid
        expect(myevent.start_time).to eq(myevent.start_time.beginning_of_month)
        expect(myevent.end_time).to eq(myevent.end_time.change(:day => 15).end_of_day)
      end

      it 'trait #with_vm_datra and full_month has a valid factory' do
        myevent = FactoryGirl.build(:showback_data_rollup, :with_vm_data, :full_month)
        myevent.valid?
        expect(myevent).to be_valid
        expect(myevent.start_time).to eq(myevent.start_time.beginning_of_month)
        expect(myevent.end_time).to eq(myevent.end_time.end_of_month)
        expect(myevent.data).to eq(
          "CPU"    => {
            "average"           => [29.8571428571429, "percent"],
            "number"            => [2.0, "cores"],
            "max_number_of_cpu" => [2, "cores"]
          },
          "MEM"    => {
            "max_mem" => [2048, "Mib"]
          },
          "FLAVOR" => {}
        )
      end

      it 'trait #with_vm_datra and half_month has a valid factory' do
        myevent = FactoryGirl.build(:showback_data_rollup, :with_vm_data, :first_half_month)
        myevent.valid?
        expect(myevent).to be_valid
        expect(myevent.start_time).to eq(myevent.start_time.beginning_of_month)
        expect(myevent.end_time).to eq(myevent.end_time.change(:day => 15).end_of_day)
        expect(myevent.data).to eq(
          "CPU"    => {
            "average"           => [29.8571428571429, "percent"],
            "number"            => [2.0, "cores"],
            "max_number_of_cpu" => [2, "cores"]
          },
          "MEM"    => {
            "max_mem" => [2048, "Mib"]
          },
          "FLAVOR" => {}
        )
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
        group = FactoryGirl.build(:showback_input_measure)
        group.save
      end

      it 'should return value of the group with field' do
        event.data = {
          'CPU' => {
            'average' => [event.resource.metrics.for_time_range(event.start_time, event.end_time).average(:cpu_usage_rate_average), "percent"]
          }
        }
        expect(event.start_time.month).to eq(event.end_time.month)
        expect(event.get_group('CPU', 'average')).to eq([event.resource.metrics.for_time_range(event.start_time, event.end_time).average(:cpu_usage_rate_average).to_s, "percent"])
      end

      it 'return nil if field is not found' do
        event.data = {
          'CPU' => {
            'average' => [event.resource.metrics.for_time_range(event.start_time, event.end_time).average(:cpu_usage_rate_average), "percent"]
          }
        }
        expect(event.get_group('CPU', 'not there')).to be_nil
      end

      it 'return nil if entity is not found' do
        event.data = {
          'CPU' => {
            'average' => [event.resource.metrics.for_time_range(event.start_time, event.end_time).average(:cpu_usage_rate_average), "percent"]
          }
        }
        expect(event.get_group('not there', 'average')).to be_nil
      end

      it 'should return [value,unit]n' do
        event.data = {"CPU" => { "average" => [52.67, "percent"]}}
        expect(event.get_group('CPU', 'average')).to eq([52.67, "percent"])
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
        5.times { FactoryGirl.create(:showback_data_rollup, :full_month) }
        2.times { FactoryGirl.create(:showback_data_rollup, :start_time => DateTime.now.utc.beginning_of_month - 1.month, :end_time => DateTime.now.utc.end_of_month - 1.month) }
        expect(described_class.events_past_month.count).to eq(2)
      end

      it 'should return events of actual month' do
        5.times { FactoryGirl.create(:showback_data_rollup, :full_month) }
        2.times do
          FactoryGirl.create(:showback_data_rollup,
                             :start_time => DateTime.now.utc.beginning_of_month - 1.month,
                             :end_time   => DateTime.now.utc.end_of_month - 1.month)
        end
        expect(described_class.events_actual_month.count).to eq(5)
      end

      it 'should return events between months' do
        3.times do
          FactoryGirl.create(:showback_data_rollup,
                             :start_time => DateTime.now.utc.beginning_of_month.change(:month =>2),
                             :end_time   => DateTime.now.utc.end_of_month.change(:month =>2))
        end
        2.times do
          FactoryGirl.create(:showback_data_rollup,
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
            "average" => [event.resource.metrics.for_time_range(event.start_time, event.end_time).average(:cpu_usage_rate_average), "percent"]
          }
        }
        new_average = (event.get_group_value("CPU", "average").to_d * event.event_days +
            event.resource.metrics.for_time_range(event.end_time, nil).average(:cpu_usage_rate_average)) / (event.event_days + 1)
        event.update_event
        expect(event.start_time.month).to eq(event.end_time.month)
        expect(event.data).to eq("CPU" => { "average" => [new_average, "percent"]})
      end

      it 'should return the max number of cpu' do
        event.data = {
          "CPU" => { "max_number_of_cpu" => [1, "cores"] }
        }
        event.update_event
        expect(event.data).to eq("CPU" => { "max_number_of_cpu" => [@vm_metrics.cpu_total_cores, "cores"] })
        event.data = {
          "CPU" => { "max_number_of_cpu" => [3, "cores"] }
        }
        event.update_event
        expect(event.start_time.month).to eq(event.end_time.month)
        expect(event.get_group("CPU", "max_number_of_cpu")).to eq([3, "cores"])
      end
    end

    context 'assign event to pool' do
      it "Return nil if not pool" do
        vm = FactoryGirl.create(:vm, :hardware => FactoryGirl.create(:hardware, :cpu1x2, :memory_mb => 4096))
        FactoryGirl.create(:showback_envelope, :resource => FactoryGirl.create(:vm, :hardware => FactoryGirl.create(:hardware, :cpu1x2, :memory_mb => 4096)))
        expect(event.find_pool(vm)).to be_nil
      end

      it "Return the correct pool" do
        vm = FactoryGirl.create(:vm, :hardware => FactoryGirl.create(:hardware, :cpu1x2, :memory_mb => 4096))
        pool = FactoryGirl.create(:showback_envelope, :resource => vm)
        expect(event.find_pool(vm)).to eq(pool)
      end

      it "Should return value of CPU data" do
        event.data = {"CPU" => { "average" => [52.67, "percent"]}}
        expect(event.get_group_value('CPU', 'average')).to eq(52.67)
      end

      it "Should return unit of CPU data" do
        event.data = {"CPU" => { "average" => [52.67, "percent"]}}
        expect(event.get_group_unit('CPU', 'average')).to eq("percent")
      end

      it "Assign resource to pool" do
        vm = FactoryGirl.create(:vm)
        pool = FactoryGirl.create(:showback_envelope, :resource => vm)
        event = FactoryGirl.create(:showback_data_rollup,
                                   :start_time => DateTime.now.utc.beginning_of_month,
                                   :end_time   => DateTime.now.utc.beginning_of_month + 2.days,
                                   :resource   => vm)

        expect(pool.showback_data_rollups.count).to eq(0)
        event.assign_resource
        expect(pool.showback_data_rollups.count).to eq(1)
        expect(pool.showback_data_rollups.include?(event)).to be_truthy
      end

      it "Assign container resource to pool" do
        con = FactoryGirl.create(:container)
        con.type = "Container"
        pool = FactoryGirl.create(:showback_envelope, :resource => con)
        event = FactoryGirl.create(:showback_data_rollup,
                                   :start_time => DateTime.now.utc.beginning_of_month,
                                   :end_time   => DateTime.now.utc.beginning_of_month + 2.days,
                                   :resource   => con)

        expect(pool.showback_data_rollups.count).to eq(0)
        event.assign_resource
        expect(pool.showback_data_rollups.count).to eq(1)
        expect(pool.showback_data_rollups.include?(event)).to be_truthy
      end

      it "Assign resource to all relational pool" do
        host = FactoryGirl.create(:host)
        vm = FactoryGirl.create(:vm, :host => host)
        pool_vm = FactoryGirl.create(:showback_envelope, :resource => vm)
        pool_host = FactoryGirl.create(:showback_envelope, :resource => host)
        event = FactoryGirl.create(:showback_data_rollup,
                                   :start_time => DateTime.now.utc.beginning_of_month,
                                   :end_time   => DateTime.now.utc.beginning_of_month + 2.days,
                                   :resource   => vm)
        event.assign_resource
        expect(pool_vm.showback_data_rollups.include?(event)).to be_truthy
        expect(pool_host.showback_data_rollups.include?(event)).to be_truthy
      end

=begin
      it "Assign a pool tag" do
        @file = StringIO.new("name,entity,entry\nJD-C-T4.0.1.44,Environment,Test")
        vm = FactoryGirl.create(:vm, :name => "JD-C-T4.0.1.44")
        event = FactoryGirl.create(:showback_data_rollup,
                                   :start_time => DateTime.now.utc.beginning_of_month,
                                   :end_time   => DateTime.now.utc.beginning_of_month + 2.days,
                                   :resource   => vm)
        entity = FactoryGirl.create(:classification, :name => 'environment', :description => 'Environment')
        entry = FactoryGirl.create(:classification, :parent_id => entity.id, :name => 'test', :description => 'Test')
        pool_cat = FactoryGirl.create(:showback_envelope, :resource => entity.tag)
        pool_ent = FactoryGirl.create(:showback_envelope, :resource => entry.tag)
        ci = ClassificationImport.upload(@file)
        ci.apply
        vm.reload
        event.collect_tags
        expect(event.context).to eq("tag" => {"environment" => ["test"]})
        event.assign_by_tag
        expect(pool_ent.showback_data_rollups.include?(event)).to be_truthy
        expect(pool_cat.showback_data_rollups.include?(event)).to be_truthy
      end
=end
    end

    context 'collect tags' do
      it "Set an empty tags in context" do
        vm = FactoryGirl.create(:vm)
        event = FactoryGirl.create(:showback_data_rollup,
                                   :start_time => DateTime.now.utc.beginning_of_month,
                                   :end_time   => DateTime.now.utc.beginning_of_month + 2.days,
                                   :resource   => vm)
        event.collect_tags
        expect(event.context).to eq("tag" => {})
      end
    end
  end
  context 'update charges' do
    let(:event_to_charge) { FactoryGirl.create(:showback_data_rollup) }
    let(:pool_of_event) do
      FactoryGirl.create(:showback_envelope,
                         :resource => event_to_charge.resource)
    end

    it "Call update charges" do
      event_to_charge.data = {
        "CPU"    => {
          "average"           => [29.8571428571429, "percent"],
          "number"            => [2.0, "cores"],
          "max_number_of_cpu" => [2, "cores"]
        },
        "MEM"    => {
          "max_mem" => [2048, "Mib"]
        },
        "FLAVOR" => {}
      }
      event_to_charge.save
      charge1 = FactoryGirl.create(:showback_data_view,
                                   :showback_envelope    => pool_of_event,
                                   :showback_data_rollup => event_to_charge,
                                   :data_snapshot        => {Time.now.utc - 5.hours => event_to_charge.data})
      data1 = charge1.data_snapshot_last
      event_to_charge.data = {
        "CPU"    => {
          "average"           => [49.8571428571429, "percent"],
          "number"            => [4.0, "cores"],
          "max_number_of_cpu" => [6, "cores"]
        },
        "MEM"    => {
          "max_mem" => [2048, "Mib"]
        },
        "FLAVOR" => {}
      }
      event_to_charge.save
      event_to_charge.update_charges
      charge1.reload
      expect(charge1.data_snapshot_last).not_to eq(data1)
    end
  end
end
