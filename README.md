# Metadata Registry API version 2.0

[![Codeship Status][codeship-badge]][codeship]
[![Code Climate][codeclimate-badge]][codeclimate]
[![Coverage Status][coveralls-badge]][coveralls]

[codeship]: https://codeship.com/projects/136545
[codeship-badge]: https://codeship.com/projects/5699f830-bd58-0133-376a-36d4fdcdb43c/status?branch=master
[codeclimate]: https://codeclimate.com/github/learningtapestry/learningregistry
[codeclimate-badge]: https://codeclimate.com/github/learningtapestry/learningregistry/badges/gpa.svg
[coveralls]: https://coveralls.io/github/learningtapestry/learningregistry?branch=master
[coveralls-badge]: https://coveralls.io/repos/github/learningtapestry/learningregistry/badge.svg?branch=master

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
This project is a community based metadata registry. It is used as the API engine underneath the CE/Registry. Also comprises the new implementation of the Learning Registry API, using a widely-used database and providing a more developer-friendly, REST-oriented environment.

### Project Status
This project is currently in testing phase. It is not for production use at this time. A running developer testbed node is located at lr-staging.learningtapestry.com

You can see more info on the development and future releases on:
  - [ROADMAP](https://github.com/learningtapestry/metadataregistry/blob/master/ROADMAP.md)
  - [CHANGELOG](https://github.com/learningtapestry/metadataregistry/blob/master/CHANGELOG.md)


## Setup

Refer to the [SETUP GUIDE](https://github.com/learningtapestry/metadataregistry/blob/master/docs/00_setup_guide.md) for info on how to install, setup and run this project.

## Resources

### Docs

You can read more on the docs folder:

- [Getting Started](https://github.com/learningtapestry/metadataregistry/blob/master/docs/01_getting_started.md)
- [CE/Registry walkthrough](https://github.com/learningtapestry/metadataregistry/blob/master/docs/02_ce-registry_walkthrough.md)
- [API Info](https://github.com/learningtapestry/metadataregistry/blob/master/docs/03_api_info.md)
- [Paradata](https://github.com/learningtapestry/metadataregistry/blob/master/docs/04_paradata.md)
- [Backup and Restore](https://github.com/learningtapestry/metadataregistry/blob/master/docs/05_backup_and_restore.md)
- [Integration Samples](https://github.com/learningtapestry/metadataregistry/blob/master/docs/06_integration_samples.md)
- [Search](https://github.com/learningtapestry/metadataregistry/blob/master/docs/07_search.md)
- [Schemas](https://github.com/learningtapestry/metadataregistry/blob/master/docs/08_schemas.md)


### Swagger documentation
The official Swagger documentation describing the API is available at
[http://lr-staging.learningtapestry.com/swagger/index.html](http://lr-staging.learningtapestry.com/swagger/index.html).
It uses [Swagger UI](https://github.com/swagger-api/swagger-ui) to present the
spec in a visually pleasant format, and also allows you to inspect and call the
available endpoints from the staging node.

For development, you can install the swagger-ui locally with:
```
bin/swagger_install
```
then access on [http://localhost:9292/swagger/index.html](http://localhost:9292/swagger/index.html).

### Postman collection
We also provide a Postman collection that contains the most up to date API
modifications. You can grab it from here:
https://www.getpostman.com/collections/bc38edc491333b643e23


## License
(c) Learning Tapestry, Inc. 2016

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
* Software design and implementation (this version): Abraham Sanchez (@aspino), Steve Midgley (@science), Anderson Cardoso (@andersoncardoso)
