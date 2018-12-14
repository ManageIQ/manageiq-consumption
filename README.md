# ManageIQ-consumption
[![Gem Version](https://badge.fury.io/rb/manageiq-consumption.svg)](https://badge.fury.io/rb/manageiq-consumption)
[![Build Status](https://travis-ci.org/ManageIQ/manageiq-consumption.svg?branch=master)](https://travis-ci.org/ManageIQ/manageiq-consumption)
[![Coverage Status](https://coveralls.io/repos/github/ManageIQ/manageiq-consumption/badge.svg?branch=master)](https://coveralls.io/github/ManageIQ/manageiq-consumption?branch=master)
[![Dependency Status](https://gemnasium.com/badges/github.com/ManageIQ/manageiq-consumption.svg)](https://gemnasium.com/github.com/ManageIQ/manageiq-consumption)

[![Gitter](https://badges.gitter.im/ManageIQ/manageiq/chargeback.svg)](https://gitter.im/ManageIQ/manageiq/chargeback?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)


[![Build history for master branch](https://buildstats.info/travisci/chart/ManageIQ/manageiq-consumption?branch=master&buildCount=50)](https://travis-ci.org/ManageIQ/manageiq-consumption/branches)

ManageIQ Gem plugin for the Consumption.

## Introduction
Manageiq-consumption is a gem replacement for chargeback/showback on manageiq.

It is being designed as a complete rewrite of [ManageIQ](https://www.mananageiq.org) chargeback code in [https://github.com/ManageIQ](https://github.com/ManageIQ).

The main reason for the effort is to make sure that ManageIQ is capable of understanding and replicating any price plan for the cloud available for customers.

#### Design principles:
- **Flexibility:** capable of supporting telco chargeback(simplified). It is based on TMForum concepts adapted to cloud
- **Performance:** reduce the time needed to generate an invoice
- **Automation:** generation of invoices should be automated, for new users, groups, or resources
- **Easy integration** with 3rd party billing and ERP systems to provide full billing and payments
- **API oriented:** Every function should be available through an API. Parts of the system will be suceptible of being substitued by an external billing system via API.

#### Concepts
Please see the [wiki](https://github.com/ManageIQ/manageiq-consumption/wiki) for updated documentation on concepts, architecture and configuration.

#### Overall project status
All the project status can be followed in:

Pivotal tracker:
[https://www.pivotaltracker.com/n/projects/1958459](https://www.pivotaltracker.com/n/projects/1958459)
Github issues:
[https://github.com/ManageIQ/manageiq-consumption/issues](https://github.com/ManageIQ/manageiq-consumption/issues)


## Demo documentation

There are instruction to perform a demo of the new system inside the code, if you want to have a look it simply:

Go to [demo section](/docs/demo/README.md)

## Development

See the section on pluggable providers in the [ManageIQ Developer Setup](http://manageiq.org/docs/guides/developer_setup)

Manageiq-consumption is not a provider, so we have adapted the development to create a gem that can be installed.

Development has been divided in phases:

- Phase 1 (current): We use the old reporting data that is fed into the new chargeback. Old chargeback rating can be deleted. Price plans are migrated into the new chargeback. It should have functional parity with the old chargeback.
- Phase 2: Reporting is changed into the new showback_event mechanism, to increase the flexibility and speed of the system
- Phase 3: Extend it into a financial management system

# Configuration

1. `cd manageiq`
1. `mkdir plugins`
1. `git clone git@github.com:ManageIQ/manageiq-consumption.git plugins/manageiq-consumption`
1. `echo "gem 'manageiq-consumption', :path => File.expand_path('../plugins/manageiq-consumption', __dir__)
" >> bundler.d/manageiq-consumption.rb`
1. `bin/update`


## License

The gem is available as open source under the terms of the [Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0).

## Contributing
**Contributions are welcomed and appreciated**

1. Fork the repo. Make sure that you can run the tests (`bundle exec rspec`)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
