#Manageiq Demo

##Install the Gem

Set in the Gemfile

```ruby
gem "manageiq-consumption",   :git => "https://github.com/miq-consumption/manageiq-consumption.git", :branch => "master"
```
## Set a play data

PATH_TO_RUBY_SEED_PLAY_FILE is in [/docs/demo/seed_play_data.rb](/docs/demo/seed_play_data.rb)

```ruby
bin/rails r PATH_TO_RUBY_SEED_PLAY_FILE
```

## Go to Rails Console

```ruby

bin/rails c
```
First we need to create ours seeds
```ruby

ManageIQ::Consumption::ShowbackUsageType.seed
ManageIQ::Consumption::ShowbackPricePlan.seed

```
We get the first Vm and his host and we define his pool

```ruby
vm = Vm.first
host = vm.host
ManageIQ::Consumption::ShowbackPool.new(:name => "Pool Vm",:description=>"First VM",:resource =>vm,:start_time => DateTime.now.beginning_of_month,:end_time => DateTime.now.end_of_month, :state => "OPEN").save
```

ConsumptionManager generate the events and we can get the event of our vm

```ruby
ManageIQ::Consumption::ConsumptionManager.generate_events
ManageIQ::Consumption::ShowbackEvent.where(:resource => vm)
```

This Event will generate with an empty data data: {"CPU"=>{"average"=>0, "number"=>0, "max_number_of_cpu"=>0}, "MEM"=>{"total_mem"=>0}}

```ruby
ManageIQ::Consumption::ConsumptionManager.update_events
```

After that if we call again to our event

```ruby
ManageIQ::Consumption::ShowbackEvent.where(:resource => vm)
```

We get an updated data data: {"CPU"=>{"average"=>"32.8571428571429", "number"=>"0.0", "max_number_of_cpu"=>1}, "MEM"=>{"total_mem"=>0}}



