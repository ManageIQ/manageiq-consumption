# Miq-Consumption
[![Gem Version](https://badge.fury.io/rb/manageiq-consumption.svg)](https://badge.fury.io/rb/manageiq-consumption)
[![Build Status](https://travis-ci.org/miq-consumption/manageiq-consumption.svg)](https://travis-ci.org/miq-consumption/manageiq-consumption)
[![Dependency Status](https://gemnasium.com/badges/github.com/miq-consumption/manageiq-consumption.svg)](https://gemnasium.com/github.com/miq-consumption/manageiq-consumption)
[![security](https://hakiri.io/github/miq-consumption/manageiq-consumption/master.svg)](https://hakiri.io/github/miq-consumption/manageiq-consumption/master)


ManageIQ Gem plugin for the Consumption.

## Development

See the section on pluggable providers in the [ManageIQ Developer Setup](http://manageiq.org/docs/guides/developer_setup)

# Configuration

1. `mkdir plugins`
1. `git clone git@github.com:miq-consumption/manageiq-consumption.git plugins/manageiq-consumption`
1. `echo "gem 'manageiq-consumption', :path => File.expand_path('plugins/manageiq-consumption', __dir__)
" >> bundler.d/miq-consumption.rb`
1. `bin/update` 



## License

The gem is available as open source under the terms of the [Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0).

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request