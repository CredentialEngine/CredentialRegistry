# Credential Registry API

[![Codeship Status][codeship-badge]][codeship]
[![Code Climate][codeclimate-badge]][codeclimate]
[![Coverage Status][coveralls-badge]][coveralls]

[codeship]: https://codeship.com/projects/210254
[codeship-badge]: https://codeship.com/projects/f0799320-f56b-0134-43c9-62cc51a71676/status?branch=master
[codeclimate]: https://codeclimate.com/github/CredentialEngine/CredentialRegistry
[codeclimate-badge]: https://codeclimate.com/github/CredentialEngine/CredentialRegistry/badges/gpa.svg
[coveralls]: https://coveralls.io/github/CredentialEngine/CredentialRegistry?branch=master
[coveralls-badge]: https://coveralls.io/repos/github/CredentialEngine/CredentialRegistry/badge.svg?branch=master

## Table of Contents
- [Introduction](#introduction)
    - [Project Status](#project-status)
- [Setup](#setup)
- [Resources](#resources)
    - [Docs](#docs)
    - [Swagger documentaion](#swagger-documentation)
    - [Postman collection](#postman-collection)
- [License](#license)
- [Credits](#credits)

## Introduction
This project is a community based metadata registry.
With it your community can have a full data store with an api, data validation and search capabilities, by just providing a simple config with a json-schema definition.

It is used as the API engine underneath the CE/Registry. Also comprises the new implementation of the Learning Registry API, using a widely-used database and providing a more developer-friendly, REST-oriented environment.

### Modeling

We organize any info into `community` buckets.
All data inside a community is abstracted in `envelopes`. These envelopes can yield any type of `resource`, encoded using `JWT`.
You can define a schema (via a `json-schema` file) for your resources.
With these configs in hand we can validate the resources, and provide a search api.

### Project Status
This project is currently in testing phase. It is not for production use at this time. A running developer testbed node is located at lr-staging.learningtapestry.com

You can see more info on the development and future releases on:
  - [ROADMAP](ROADMAP.md)
  - [CHANGELOG](CHANGELOG.md)


## Setup

Refer to the [SETUP GUIDE](/docs/00_setup_guide.md) for info on how to install, setup and run this project.

## Resources

### Docs

You can read more on the docs folder:

- [Getting Started](/docs/01_getting_started.md)
- [CE/Registry walkthrough](/docs/02_ce-registry_walkthrough.md)
- [API Info](/docs/03_api_info.md)
- [Paradata](/docs/04_paradata.md)
- [Backup and Restore](/docs/05_backup_and_restore.md)
- [Integration Samples](/docs/06_integration_samples.md)
- [Search](/docs/07_search.md)
- [Schemas](/docs/08_schemas.md)


### Swagger documentation
The official Swagger documentation describing the API is available at
[http://lr-staging.learningtapestry.com/swagger/index.html](http://lr-staging.learningtapestry.com/swagger/index.html).
It uses [Swagger UI](https://github.com/swagger-api/swagger-ui) to present the
spec in a visually pleasant format, and also allows you to inspect and call the
available endpoints from the staging node.

For development, you can install the swagger-ui locally with:
```
bin/install_swagger
```
then access on [http://localhost:9292/swagger/index.html](http://localhost:9292/swagger/index.html).

### Postman collection
We also provide a Postman collection that contains the most up to date API
modifications. You can grab it from here:
https://www.getpostman.com/collections/bc38edc491333b643e23

### Archive.org Backups
We back up daily transactions to Archive.org. The packages are available at the [ce-registry archive](https://archive.org/details/ce-registry) ([S3-compatible bucket](http://s3.us.archive.org/ce-registry)).

## License
(c) Learning Tapestry, Inc. 2021

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

## Credits
* Primary architecture and design (from version 1+): Steve Midgley (@science), Joe Hobson (@joehobson), Abraham Sanchez (@aspino), RM Saksida (@rmsaksida), Jason Hoekstra (@jasonhoekstra), Jim Klo (@jimklo), Walt Grata (@wegrata), Marie Bienkowski (@marbienk), Dan Rehak, Suraiya Suliman (@ssuliman), John Weatherley, Susan Van Gundy, Paul Jesukiewicz
* Software design and implementation (this version): Abraham Sanchez (@aspino), Steve Midgley (@science), Anderson Cardoso (@andersoncardoso), RM Saksida (@rmsaksida), Alex Nizamov (@excelsior)
