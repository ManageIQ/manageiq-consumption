# Manageiq Demo

## Install the Gem in manageiq

Set in the Gemfile (for development, demos, you can use a .rb file in /bundler.d)

```ruby
gem "manageiq-consumption",   :git => "https://github.com/ManageIQ/manageiq-consumption.git", :branch => "master"
```
## Set a play data

PATH_TO_RUBY_SEED_PLAY_FILE is in [/docs/demo/seed_play_data.rb](/docs/demo/seed_play_data.rb)

```ruby
bin/rails r PATH_TO_RUBY_SEED_PLAY_FILE
```

### You could use a console where the information is deleted after you get out

```ruby
bin/rails c -s
```

```ruby
load PATH_TO_RUBY_SEED_PLAY_FILE
```

## Go to Rails Console if you haven't used the temporary console

```ruby

bin/rails c
```
First we need to create ours seeds
```ruby

ManageIQ::Consumption::ShowbackUsageType.seed
ManageIQ::Consumption::ShowbackPricePlan.seed

```
We get the first Vm and his host and we define a pool associated to the host

```ruby
host = Host.first
ManageIQ::Consumption::ShowbackPool.new(:name => "Pool host",:description=>"First host",:resource =>host,:start_time => DateTime.now.beginning_of_month,:end_time => DateTime.now.end_of_month, :state => "OPEN").save
```

ConsumptionManager generate the events and we can get the event of the first vm of this host

```ruby
ManageIQ::Consumption::ShowbackEvent.count
# Returns 0
ManageIQ::Consumption::ConsumptionManager.generate_events
ManageIQ::Consumption::ShowbackEvent.where(:resource => host.vms.first)
```

This Event will generate with an empty data data: {"CPU"=>{"average"=>0, "number"=>0, "max_number_of_cpu"=>0}, "MEM"=>{"total_mem"=>0}} and context {"tag"=>{"location"=>["chicago"]}}

```ruby
ManageIQ::Consumption::ConsumptionManager.update_events
```

After that if we call again to our event

```ruby
ManageIQ::Consumption::ShowbackEvent.where(:resource => host.vms.first)
```

We get an updated data data: {"CPU"=>{"average"=>"51.7142857142857", "number"=>"0.0", "max_number_of_cpu"=>1}, "MEM"=>{"total_mem"=>0}}


Now we can check that there is 4 events in the pool of the host, one event for each vm.

```ruby
pool = ManageIQ::Consumption::ShowbackPool.first
pool.showback_events
```

If we get the sum of this charges we get #<Money fractional:0 currency:USD>,
there are not charges nor price plans associated to the pool

```ruby
pool.sum_of_charges
```
Now we can add some charges 

```ruby
pool.add_charge(pool.showback_events.first,10)
pool.add_charge(pool.showback_events.second,20)
pool.showback_charges.reload
```
And if we make now the sum we get the total <Money fractional:30 currency:USD>
```ruby
pool.sum_of_charges
```

# Showback

Now we can define our PricePlan, we create one associated with our host.

```ruby
ManageIQ::Consumption::ShowbackPricePlan.create(:name => "Host in chicago",:description=>"This host is in chicago",:resource => host).save
plan = ManageIQ::Consumption::ShowbackPricePlan.where(:name=>"Host in chicago").first
```

And we define our rate

```ruby
ManageIQ::Consumption::ShowbackRate.create(:showback_price_plan => plan,
                                           :fixed_rate          => Money.new(11),
                                           :variable_rate       => Money.new(7),
                                           :calculation         => "duration",
                                           :category            => "CPU",
                                           :dimension           => "max_number_of_cpu").save!
```

Now the rate is associated to the price plan, and thus if you call calculate_charge in the pool it will use it
