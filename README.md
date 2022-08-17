# ManageIQ::Consumption

[![CI](https://github.com/ManageIQ/manageiq-consumption/actions/workflows/ci.yaml/badge.svg?branch=oparin)](https://github.com/ManageIQ/manageiq-consumption/actions/workflows/ci.yaml)
[![Maintainability](https://api.codeclimate.com/v1/badges/7ddcfc7e53574d375f43/maintainability)](https://codeclimate.com/github/ManageIQ/manageiq-consumption/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/7ddcfc7e53574d375f43/test_coverage)](https://codeclimate.com/github/ManageIQ/manageiq-consumption/test_coverage)

[![Chat](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/ManageIQ/manageiq/chargeback?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

[![Build history for oparin branch](https://buildstats.info/github/chart/ManageIQ/manageiq-consumption?branch=oparin&buildCount=50&includeBuildsFromPullRequest=false&showstats=false)](https://github.com/ManageIQ/manageiq-consumption/actions?query=branch%3Amaster)

Consumption plugin for ManageIQ.

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

#### Development Phases

Development has been divided in phases:

- Phase 1 (current): We use the old reporting data that is fed into the new chargeback. Old chargeback rating can be deleted. Price plans are migrated into the new chargeback. It should have functional parity with the old chargeback.
- Phase 2: Reporting is changed into the new showback_event mechanism, to increase the flexibility and speed of the system
- Phase 3: Extend it into a financial management system

## Demo documentation

There are instruction to perform a demo of the new system inside the code, if you want to have a look it simply:

Go to [demo section](/docs/demo/README.md)

## Development

See the section on plugins in the [ManageIQ Developer Setup](http://manageiq.org/docs/guides/developer_setup/plugins)

For quick local setup run `bin/setup`, which will clone the core ManageIQ repository under the *spec* directory and setup necessary config files. If you have already cloned it, you can run `bin/update` to bring the core ManageIQ code up to date.

## License

The gem is available as open source under the terms of the [Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0).

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
