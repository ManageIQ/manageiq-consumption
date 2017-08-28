
ManageIQ::Consumption::ConsumptionManager.seed

def generateHardware(n)
  h = Hardware.new
  h.cpu_sockets = n
  h.cpu_cores_per_socket = n%2
  h.cpu_total_cores = n
  h.memory_mb = n*2048
  h.save
  return h
end

#RHEV ExtManagement
ext = ExtManagementSystem.new
ext.name = "RHEV"
ext.zone = Zone.first
ext.hostname = "rhev.manageiq.consumption"
ext.save

for i in 1..9 do
  h            = Host.new
  h.name       = "host_#{i}"
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
  for n in 1..4 do
    v      = Vm.new
    v.name = "vm_#{n}"
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
    date_seed = DateTime.now + 5.hours
    times = [
        date_seed,
        date_seed + 1.days,
        date_seed + 1.days + 3.hours,
        date_seed + 2.days + 4.hours,
        date_seed + 2.days + 5.hours,
        date_seed + 2.days,
        date_seed + 3.days,
    ]
    times.each do |t|
      v.metrics << Metric.create(
          :capture_interval_name => "realtime",
          :resource_type         => "Vm",
          :timestamp                  => t,
          :cpu_usage_rate_average     => rand(0...100),
          # Multiply by a factor of 1000 to make it more realistic and enable testing virtual col v_pct_cpu_ready_delta_summation
          :cpu_ready_delta_summation  => rand(0...100) * 1000,
          :sys_uptime_absolute_latest => rand(0...100)
      )
    end
  end
end

