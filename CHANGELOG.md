# Changelog

All notable changes to `barber-saas-infra-postgres` are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2026-10-08

MVP 2 (corte 2): first release of this repository to `main`, promoted from `develop` through `qa`
with `git cherry-pick -x` (norm 10–11).

User stories: code-corhuila/barber-saas-docs#3, code-corhuila/barber-saas-docs#4, code-corhuila/barber-saas-docs#5, code-corhuila/barber-saas-docs#6, code-corhuila/barber-saas-docs#7, code-corhuila/barber-saas-docs#9, code-corhuila/barber-saas-docs#10, code-corhuila/barber-saas-docs#12, code-corhuila/barber-saas-docs#59.

### Added

- **postgres:** add the single postgresql instance with its volume
- **postgres:** create the extensions and one user per domain on first start
- **env:** add one variables file per environment
- **scripts:** start, migrate and stop the platform per environment
- **scripts:** generate development rs256 keys and tokens
- **observability:** add the collector, prometheus and grafana under a profile
- **compose:** include the identity-auth schema runner and service
- **compose:** include the api gateway
- **compose:** include barbershop and schedule in the platform
- **compose:** include schedule-api in the platform
- **compose:** include appointment in the platform
- **compose:** include the workflow in the platform
- **keys:** issue the barbershop and schedule service tokens
- **keys:** issue the platform-admin service token
- **compose:** include the single MongoDB instance in the platform
- **compose:** include finance-inventory-db in the platform
- **compose:** include finance-inventory-api in the platform
- **compose:** include platform-admin in the platform
- **scripts:** create the development SUPER_ADMIN
- **compose:** include the worker in the platform
- **compose:** include notifications-api in the platform
- **compose:** migrate the notifications database with the platform
- **compose:** include loyalty-db in the platform
- **compose:** include loyalty-api in the platform

### Fixed

- **postgres:** create the btree_gist extension in the instance
- **scripts:** apply the instance script again before migrating
- **scripts:** issue one development service token per service

### Documentation

- **readme:** explain how to start the platform and where the data is
- **readme:** explain that migrate.sh refreshes the instance first
- **readme:** list what the platform composes today
- **readme:** use the new repository name barber-saas-infra-postgres
- **readme:** point the header to Barber Saas and barber-saas-docs

### Maintenance

- **infra:** ignore local env files and keys
- **infra:** keep shell scripts with lf line endings
- **github:** add the pull request template
- **github:** track the story environment on the board
- **env:** name the two service tokens in every environment
- **env:** name the domain service tokens in every environment
- **env:** name the FCM service account variable
- refuse env files, Firebase files and keys in any pull request
- skip the workflow's own pattern and print only file names
- **env:** name the smtp variables of the password-reset e-mail

[2.0.0]: https://github.com/code-corhuila/barber-saas-infra-postgres/releases/tag/v2.0.0
