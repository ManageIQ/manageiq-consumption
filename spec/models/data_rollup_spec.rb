require 'spec_helper'
require 'money-rails/test_helpers'

describe ManageIQ::Showback::DataRollup do
  let(:data_rollup) { FactoryBot.build(:data_rollup) }
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
      vm = FactoryBot.create(:vm)
      data_rollup.resource = vm
      expect(data_rollup).to be_valid
    end

    it 'should generate data' do
      data_rollup.data = {}
      data_rollup.resource = FactoryBot.create(:vm)
      hash = {}
      ManageIQ::Showback::InputMeasure.seed
      data_units = ManageIQ::Showback::Manager.load_column_units
      ManageIQ::Showback::InputMeasure.all.each do |group_type|
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
      data_rollup = FactoryBot.create(:data_rollup)
      expect(data_rollup.validate_format).to be_nil
    end

    it 'fails validations with incorrect JSON data' do
      data_rollup = FactoryBot.build(:data_rollup, :data => ":-Invalid:\n-JSON")
      expect(data_rollup.validate_format).to be_nil
    end

    it 'returns nil if ParserError' do
      data_rollup = FactoryBot.create(:data_rollup)
      data_rollup.data = "abc"
      expect(data_rollup.validate_format).to be_nil
    end
  end

  context '#engine' do
    let(:vm)               { FactoryBot.create(:vm) }
    let(:data_rollup)      { FactoryBot.build(:data_rollup, :full_month) }
    let(:vm_data_rollup)   { FactoryBot.build(:data_rollup, :with_vm_data, :first_half_month) }
    describe 'Basic' do
      it 'should return the object' do
        data_rollup.resource = vm
        expect(data_rollup.resource).to eq(vm)
      end
      it 'trait #full_month should have a valid factory' do
        mydata_rollup = FactoryBot.build(:data_rollup, :full_month)
        mydata_rollup.valid?
        expect(mydata_rollup).to be_valid
        expect(mydata_rollup.start_time).to eq(mydata_rollup.start_time.beginning_of_month)
        expect(mydata_rollup.end_time).to eq(mydata_rollup.end_time.end_of_month)
      end

      it 'trait #with_vm_data should have a valid factory' do
        mydata_rollup = FactoryBot.build(:data_rollup, :with_vm_data)
        mydata_rollup.valid?
        expect(mydata_rollup.data).to eq(
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
        expect(mydata_rollup).to be_valid
      end

      it 'trait #first_half_month should have a valid factory' do
        mydata_rollup = FactoryBot.build(:data_rollup, :first_half_month)
        mydata_rollup.valid?
        expect(mydata_rollup).to be_valid
        expect(mydata_rollup.start_time).to eq(mydata_rollup.start_time.beginning_of_month)
        expect(mydata_rollup.end_time).to eq(mydata_rollup.end_time.change(:day => 15).end_of_day)
      end

      it 'trait #with_vm_datra and full_month has a valid factory' do
        mydata_rollup = FactoryBot.build(:data_rollup, :with_vm_data, :full_month)
        mydata_rollup.valid?
        expect(mydata_rollup).to be_valid
        expect(mydata_rollup.start_time).to eq(mydata_rollup.start_time.beginning_of_month)
        expect(mydata_rollup.end_time).to eq(mydata_rollup.end_time.end_of_month)
        expect(mydata_rollup.data).to eq(
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
        mydata_rollup = FactoryBot.build(:data_rollup, :with_vm_data, :first_half_month)
        mydata_rollup.valid?
        expect(mydata_rollup).to be_valid
        expect(mydata_rollup.start_time).to eq(mydata_rollup.start_time.beginning_of_month)
        expect(mydata_rollup.end_time).to eq(mydata_rollup.end_time.change(:day => 15).end_of_day)
        expect(mydata_rollup.data).to eq(
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

    context 'update data_rollups' do
      before(:each) do
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
          @vm_metrics.metrics << FactoryBot.create(
            :metric_vm_rt,
            :timestamp                  => t,
            :cpu_usage_rate_average     => v,
            # Multiply by a factor of 1000 to make it more realistic and enable testing virtual col v_pct_cpu_ready_delta_summation
            :cpu_ready_delta_summation  => v * 1000,
            :sys_uptime_absolute_latest => v
          )
        end
        data_rollup.resource     = @vm_metrics
        data_rollup.start_time   = "2010-04-13T00:00:00Z"
        data_rollup.end_time     = "2010-04-14T00:00:00Z"
        group = FactoryBot.build(:input_measure)
        group.save
      end

      it 'should return value of the group with field' do
        data_rollup.data = {
          'CPU' => {
            'average' => [data_rollup.resource.metrics.for_time_range(data_rollup.start_time, data_rollup.end_time).average(:cpu_usage_rate_average), "percent"]
          }
        }
        expect(data_rollup.start_time.month).to eq(data_rollup.end_time.month)
        expect(data_rollup.get_group('CPU', 'average')).to eq([data_rollup.resource.metrics.for_time_range(data_rollup.start_time, data_rollup.end_time).average(:cpu_usage_rate_average).to_s, "percent"])
      end

      it 'return nil if field is not found' do
        data_rollup.data = {
          'CPU' => {
            'average' => [data_rollup.resource.metrics.for_time_range(data_rollup.start_time, data_rollup.end_time).average(:cpu_usage_rate_average), "percent"]
          }
        }
        expect(data_rollup.get_group('CPU', 'not there')).to be_nil
      end

      it 'return nil if entity is not found' do
        data_rollup.data = {
          'CPU' => {
            'average' => [data_rollup.resource.metrics.for_time_range(data_rollup.start_time, data_rollup.end_time).average(:cpu_usage_rate_average), "percent"]
          }
        }
        expect(data_rollup.get_group('not there', 'average')).to be_nil
      end

      it 'should return [value,unit]n' do
        data_rollup.data = {"CPU" => { "average" => [52.67, "percent"]}}
        expect(data_rollup.get_group('CPU', 'average')).to eq([52.67, "percent"])
      end

      it 'should return metrics time range' do
        expect(data_rollup.metrics_time_range("2010-04-14T20:00:00Z", "2010-04-15T22:00:00Z").count).to eq(4)
      end

      it 'should return 0 metrics if start time is nil' do
        expect(data_rollup.metrics_time_range(nil, "2010-04-14T21:00:00Z").count).to eq(0)
      end

      it 'should return metrics over time range' do
        expect(data_rollup.metrics_time_range("2010-04-14T22:00:00Z", nil).count).to eq(4)
      end

      it 'should return data_rollups of past month' do
        5.times { FactoryBot.create(:data_rollup, :full_month) }
        2.times { FactoryBot.create(:data_rollup, :start_time => DateTime.now.utc.beginning_of_month - 1.month, :end_time => DateTime.now.utc.end_of_month - 1.month) }
        expect(described_class.data_rollups_past_month.count).to eq(2)
      end

      it 'should return data_rollups of actual month' do
        5.times { FactoryBot.create(:data_rollup, :full_month) }
        2.times do
          FactoryBot.create(:data_rollup,
                             :start_time => DateTime.now.utc.beginning_of_month - 1.month,
                             :end_time   => DateTime.now.utc.end_of_month - 1.month)
        end
        expect(described_class.data_rollups_actual_month.count).to eq(5)
      end

      it 'should return data_rollups between months' do
        3.times do
          FactoryBot.create(:data_rollup,
                             :start_time => DateTime.now.utc.beginning_of_month.change(:month =>2),
                             :end_time   => DateTime.now.utc.end_of_month.change(:month =>2))
        end
        2.times do
          FactoryBot.create(:data_rollup,
                             :start_time => DateTime.now.utc.beginning_of_month.change(:month =>4),
                             :end_time   => DateTime.now.utc.end_of_month.change(:month =>4))
        end
        expect(described_class.data_rollups_between_month(1, 3).count).to eq(3)
        # data_rollups_between_month
      end

      it 'should return number of days between start_time and end_time' do
        data_rollup.start_time = "2010-04-10T00:00:00Z"
        data_rollup.end_time   = "2010-04-14T00:00:00Z"
        expect(data_rollup.data_rollup_days).to eq(4)
      end

      it 'should update data data_rollup with average metrics' do
        data_rollup.start_time = "2010-04-13T00:00:00Z"
        data_rollup.end_time   = "2010-04-14T22:52:30Z"
        data_rollup.data = {
          "CPU" => {
            "average" => [data_rollup.resource.metrics.for_time_range(data_rollup.start_time, data_rollup.end_time).average(:cpu_usage_rate_average), "percent"]
          }
        }
        new_average = (data_rollup.get_group_value("CPU", "average").to_d * data_rollup.data_rollup_days +
            data_rollup.resource.metrics.for_time_range(data_rollup.end_time, nil).average(:cpu_usage_rate_average)) / (data_rollup.data_rollup_days + 1)
        data_rollup.update_data_rollup
        expect(data_rollup.start_time.month).to eq(data_rollup.end_time.month)
        expect(data_rollup.data).to eq("CPU" => { "average" => [new_average, "percent"]})
      end

      it 'should return the max number of cpu' do
        data_rollup.data = {
          "CPU" => { "max_number_of_cpu" => [1, "cores"] }
        }
        data_rollup.update_data_rollup
        expect(data_rollup.data).to eq("CPU" => { "max_number_of_cpu" => [@vm_metrics.cpu_total_cores, "cores"] })
        data_rollup.data = {
          "CPU" => { "max_number_of_cpu" => [3, "cores"] }
        }
        data_rollup.update_data_rollup
        expect(data_rollup.start_time.month).to eq(data_rollup.end_time.month)
        expect(data_rollup.get_group("CPU", "max_number_of_cpu")).to eq([3, "cores"])
      end
    end

    context 'assign data_rollup to envelope' do
      it "Return nil if not envelope" do
        vm = FactoryBot.create(:vm, :hardware => FactoryBot.create(:hardware, :cpu1x2, :memory_mb => 4096))
        FactoryBot.create(:envelope, :resource => FactoryBot.create(:vm, :hardware => FactoryBot.create(:hardware, :cpu1x2, :memory_mb => 4096)))
        expect(data_rollup.find_envelope(vm)).to be_nil
      end

      it "Return the correct envelope" do
        vm = FactoryBot.create(:vm, :hardware => FactoryBot.create(:hardware, :cpu1x2, :memory_mb => 4096))
        envelope = FactoryBot.create(:envelope, :resource => vm)
        expect(data_rollup.find_envelope(vm)).to eq(envelope)
      end

      it "Should return value of CPU data" do
        data_rollup.data = {"CPU" => { "average" => [52.67, "percent"]}}
        expect(data_rollup.get_group_value('CPU', 'average')).to eq(52.67)
      end

      it "Should return unit of CPU data" do
        data_rollup.data = {"CPU" => { "average" => [52.67, "percent"]}}
        expect(data_rollup.get_group_unit('CPU', 'average')).to eq("percent")
      end

      it "Assign resource to envelope" do
        vm = FactoryBot.create(:vm)
        envelope = FactoryBot.create(:envelope, :resource => vm)
        data_rollup = FactoryBot.create(:data_rollup,
                                         :start_time => DateTime.now.utc.beginning_of_month,
                                         :end_time   => DateTime.now.utc.beginning_of_month + 2.days,
                                         :resource   => vm)

        expect(envelope.data_rollups.count).to eq(0)
        data_rollup.assign_resource
        expect(envelope.data_rollups.count).to eq(1)
        expect(envelope.data_rollups.include?(data_rollup)).to be_truthy
      end

      it "Assign container resource to envelope" do
        con = FactoryBot.create(:container)
        con.type = "Container"
        envelope = FactoryBot.create(:envelope, :resource => con)
        data_rollup = FactoryBot.create(:data_rollup,
                                         :start_time => DateTime.now.utc.beginning_of_month,
                                         :end_time   => DateTime.now.utc.beginning_of_month + 2.days,
                                         :resource   => con)

        expect(envelope.data_rollups.count).to eq(0)
        data_rollup.assign_resource
        expect(envelope.data_rollups.count).to eq(1)
        expect(envelope.data_rollups.include?(data_rollup)).to be_truthy
      end

      it "Assign resource to all relational envelope" do
        host = FactoryBot.create(:host)
        vm = FactoryBot.create(:vm, :host => host)
        envelope_vm = FactoryBot.create(:envelope, :resource => vm)
        envelope_host = FactoryBot.create(:envelope, :resource => host)
        data_rollup = FactoryBot.create(:data_rollup,
                                         :start_time => DateTime.now.utc.beginning_of_month,
                                         :end_time   => DateTime.now.utc.beginning_of_month + 2.days,
                                         :resource   => vm)
        data_rollup.assign_resource
        expect(envelope_vm.data_rollups.include?(data_rollup)).to be_truthy
        expect(envelope_host.data_rollups.include?(data_rollup)).to be_truthy
      end

      it "Assign a envelope tag" do
        @file = StringIO.new("name,entity,entry\nJD-C-T4.0.1.44,Environment,Test")
        vm = FactoryBot.create(:vm, :name => "JD-C-T4.0.1.44")
        data_rollup = FactoryBot.create(:data_rollup,
                                         :start_time => DateTime.now.utc.beginning_of_month,
                                         :end_time   => DateTime.now.utc.beginning_of_month + 2.days,
                                         :resource   => vm)
        entity = FactoryBot.create(:classification, :name => 'environment', :description => 'Environment')
        entry = FactoryBot.create(:classification_tag, :parent => entity, :name => 'test', :description => 'Test')
        entry.assign_entry_to(vm)
        envelope_cat = FactoryBot.create(:envelope, :resource => entity.tag)
        envelope_ent = FactoryBot.create(:envelope, :resource => entry.tag)
        ci = ClassificationImport.upload(@file)
        ci.apply
        vm.reload
        data_rollup.collect_tags
        expect(data_rollup.context).to eq("tag" => {"environment" => ["test"]})
        data_rollup.assign_by_tag
        expect(envelope_ent.data_rollups.include?(data_rollup)).to be_truthy
        expect(envelope_cat.data_rollups.include?(data_rollup)).to be_truthy
      end
    end

    context 'collect tags' do
      it "Set an empty tags in context" do
        vm = FactoryBot.create(:vm)
        data_rollup = FactoryBot.create(:data_rollup,
                                         :start_time => DateTime.now.utc.beginning_of_month,
                                         :end_time   => DateTime.now.utc.beginning_of_month + 2.days,
                                         :resource   => vm)
        data_rollup.collect_tags
        expect(data_rollup.context).to eq("tag" => {})
      end
    end
  end
  context 'update data_views' do
    let(:data_rollup_data) { FactoryBot.create(:data_rollup) }
    let(:envelope_of_data_rollup) do
      FactoryBot.create(:envelope,
                         :resource => data_rollup_data.resource)
    end

    it "Call update data_views" do
      data_rollup_data.data = {
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
      data_rollup_data.save
      data_view1 = FactoryBot.create(:data_view,
                                      :envelope      => envelope_of_data_rollup,
                                      :data_rollup   => data_rollup_data,
                                      :data_snapshot => {Time.now.utc - 5.hours => data_rollup_data.data})
      data1 = data_view1.data_snapshot_last
      data_rollup_data.data = {
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
      data_rollup_data.save
      data_rollup_data.update_data_views
      data_view1.reload
      expect(data_view1.data_snapshot_last).not_to eq(data1)
    end
  end
end
