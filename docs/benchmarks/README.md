# Benchmarks

## EVENTS
### Runner

PATH_TO_RUBY_BENCHMARK_FILE = [/docs/benchmarks/benchmark_events.rb](/docs/benchmarks/benchmark_events.rb)

INPUT 4 integers.

- PROVIDERS (default 2) 
- HOSTS x PROVIDERS (default 2) 
- VMS X HOSTS x PROVIDERS (default 4) 
- METRICS X VMS X HOSTS x PROVIDERS (default 10) 
- NEWMETRICS to add for each vm after first event generation (default 4) 

Example 
```ruby

bin/rails r PATH_TO_RUBY_BENCHMARK_FILE 2 2 4 10 4

```

This generate:

 - 2 providers with 3 hosts each provider (6 hosts)
 - 4 vms each hosts (24 vms)
 - 10 metrics by vm (240 metrics) 


Output

```bash
Benchmark show user CPU time, system CPU time and elapsed real time
Generating infrastructure for 2 providers with 2 hosts and 4 vms for each host, the vms have 10 metrics and 4 after generate
Generated infrastructure in 7.199999999999999 0.6799999999999999 10.425814000000173
Generated ShowbackUsageType seed in 0.010000000000001563 0.0 0.0137959999992745
Generated ShowbackPricePlan seed in 0.05999999999999872 0.0 0.058042000000568805
Generated Pools for 2 Providers0.02000000000000135 0.010000000000000231 0.02380999999877531
Generated events for 16 vms in 6.8199999999999985 0.19999999999999973 7.687425000000076
Updating  events in 6.359999999999999 0.1499999999999999 8.571742000000086
Adding new metrics 4 x 4 (16) vms in 6.190000000000001 0.3900000000000001 14.060204999999769
Updating events with new metrics in 7.159999999999997 0.20000000000000018 10.020586000000549
Clean infrastructure in 0.010000000000005116 0.0 0.019666000000142958
```