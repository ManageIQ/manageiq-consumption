require 'benchmark'

PROVIDERS = ARGV[0] || 2
HOSTS     = ARGV[1] || 2
VMS       = ARGV[2] || 4
METRICS   = ARGV[3] || 10
NEWMETRICS = ARGV[4] || 4


class String
  def black;          "\033[30m#{self}\033[0m" end
  def red;            "\033[31m#{self}\033[0m" end
  def green;          "\033[32m#{self}\033[0m" end
  def brown;          "\033[33m#{self}\033[0m" end
  def blue;           "\033[34m#{self}\033[0m" end
  def magenta;        "\033[35m#{self}\033[0m" end
  def cyan;           "\033[36m#{self}\033[0m" end
  def gray;           "\033[37m#{self}\033[0m" end
end

def generateHardware(n)
  h = Hardware.new
  h.cpu_sockets = n
  h.cpu_cores_per_socket = n%2
  h.cpu_total_cores = n
  h.memory_mb = n*2048
  h.save
  return h
end


def generateInfrastructure
  date_seed = DateTime.now + 5.hours
  for i in 0..PROVIDERS.to_i do
    ext = ExtManagementSystem.new
    ext.name = "Provider_#{i}"
    ext.zone = Zone.first
    ext.hostname = "rhev.manageiq.consumption"
    ext.save
    for h in 0..HOSTS.to_i do
      h            = Host.new
      h.name       = "Host_#{i}"
      h.hardware   = generateHardware(i)
      h.hostname   = "hostname_#{i}"
      h.vmm_vendor = "redhat"
      h.ems_id     = ext.id
      if i%2==0
        h.tags=Tag.where(:name => "/managed/location/ny")
      else
        h.tags=Tag.where(:name => "/managed/location/chicago")
      end
      h.save
      for n in 0..VMS.to_i do
        v      = Vm.new
        v.name = "Vm_#{n}"
        v.location = "unknown"
        v.hardware = generateHardware(n)
        v.vendor = "redhat"
        v.template = false
        v.host_id = h.id
        v.ems_id = ext.id
        v.save
        if i%2==0
          v.tags=Tag.where(:name => "/managed/location/ny")
        else
          v.tags=Tag.where(:name => "/managed/location/chicago")
        end
        v.save
        for m in 0..METRICS.to_i do
          v.metrics << Metric.create(
              :capture_interval_name => "realtime",
              :resource_type         => "Vm",
              :timestamp                  => date_seed + m.hours + rand(0...2).days,
              :cpu_usage_rate_average     => rand(0...100),
              # Multiply by a factor of 1000 to make it more realistic and enable testing virtual col v_pct_cpu_ready_delta_summation
              :cpu_ready_delta_summation  => rand(0...100) * 1000,
              :sys_uptime_absolute_latest => rand(0...100)
          )
        end
      end
    end
  end
end

def add_new_metrics
  date_seed = DateTime.now + 5.hours
  Vm.all.each do |v|
    for m in 0..NEWMETRICS.to_i do
      v.metrics << Metric.create(
          :capture_interval_name => "realtime",
          :resource_type         => "Vm",
          :timestamp                  => date_seed + METRICS.to_i.hours + 3.days + m.hours,
          :cpu_usage_rate_average     => rand(0...100),
          # Multiply by a factor of 1000 to make it more realistic and enable testing virtual col v_pct_cpu_ready_delta_summation
          :cpu_ready_delta_summation  => rand(0...100) * 1000,
          :sys_uptime_absolute_latest => rand(0...100)
      )
    end
  end
end

def cleanInfrastructure
  ExtManagementSystem.delete_all
  Host.delete_all
  Vm.delete_all
  Metric.delete_all
  ManageIQ::Consumption::ShowbackUsageType.delete_all
  ManageIQ::Consumption::ShowbackPricePlan.delete_all
  ManageIQ::Consumption::ShowbackEvent.delete_all
  ManageIQ::Consumption::ShowbackPool.delete_all
  ManageIQ::Consumption::ShowbackRate.delete_all
  ManageIQ::Consumption::ShowbackCharge.delete_all
end

def getPrettyBenchmark(array)
    "#{array[1].to_s.brown} #{array[2].to_s.blue} #{array[5].to_s.green}"
end

puts "Benchmark show user CPU time, system CPU time and elapsed real time"
puts "Generating infrastructure for #{PROVIDERS} providers with #{HOSTS} hosts and #{VMS} vms for each host, the vms have #{METRICS} metrics and #{NEWMETRICS} after generate"
puts "Generated infrastructure in " + getPrettyBenchmark(Benchmark.measure {generateInfrastructure()}.to_a)
puts "Generated ShowbackUsageType seed in " + getPrettyBenchmark(Benchmark.measure {ManageIQ::Consumption::ShowbackUsageType.seed}.to_a)
puts "Generated ShowbackPricePlan seed in " + getPrettyBenchmark(Benchmark.measure {ManageIQ::Consumption::ShowbackPricePlan.seed}.to_a)
puts "Generated Pools for #{PROVIDERS} Providers " + getPrettyBenchmark(Benchmark.measure {
                                                            ExtManagementSystem.all.each do |provider|
                                                              ManageIQ::Consumption::ShowbackPool.new(
                                                                  :name => "Pool #{provider.name}",
                                                                  :description=>"one provider",
                                                                  :resource =>provider,
                                                                  :start_time => DateTime.now.beginning_of_month,
                                                                  :end_time => DateTime.now.end_of_month,
                                                                  :state => "OPEN").save
                                                            end
                                                    }.to_a)
puts "Generated events for #{PROVIDERS.to_i*HOSTS.to_i*VMS.to_i} vms in "+ getPrettyBenchmark(Benchmark.measure {ManageIQ::Consumption::ConsumptionManager.generate_events}.to_a)
puts "Updating  events in "+ getPrettyBenchmark(Benchmark.measure {ManageIQ::Consumption::ConsumptionManager.update_events}.to_a)
puts "Adding new metrics #{NEWMETRICS} x #{VMS} (#{NEWMETRICS.to_i * VMS.to_i}) vms in "+ getPrettyBenchmark(Benchmark.measure {add_new_metrics}.to_a)
puts "Updating events with new metrics in "+ getPrettyBenchmark(Benchmark.measure {ManageIQ::Consumption::ConsumptionManager.update_events}.to_a)
puts "Clean infrastructure in " + getPrettyBenchmark(Benchmark.measure {cleanInfrastructure()}.to_a)

