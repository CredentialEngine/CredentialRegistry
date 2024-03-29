# Installation

- [Regular setup](#regular-setup)
  - [Requirements](#requirements)
      - [Ruby](#ruby)
      - [Postgres](#postgres)
  - [Setup](#setup)
- [Vagrant VM](#vagrant-vm)
- [Basic usage](#basic-usage)
- [Running the tests](#running-the-tests)

You can install and setup the project in three ways. Either by Docker, configuring your
own machine or running a vagrant VM.

## Docker setup

The repository contains `Dockerfile` and `docker-compose.yml` required to run basic stack of the application.

```
$> docker-compose up
$> docker-compose run app rake db:create db:migrate
$> docker-compose run app rake db:seed
$> docker-compose run app rake schemas:load
```

### Environment variables

There are `.env` and `.env.docker` files present in the repository that are not to be changed in order to run the application.

`.env` serves as a template to create your own `.env.local` and last fallback.

`.env.docker` is loaded by docker-compose and is used to point the services to proper data containers within Docker environment.

Any required variable overrides should be in `.env.local` or `.env.{development|test}.local` files which are ignored by git. Check `config/dotenv_load.rb` for reference.

## Regular setup

using your own machine, please install the requirements below.

### Requirements

#### Ruby
We recommend using one of the following Ruby platforms:

* MRI version 2.3.1 or higher
* JRuby version 9.1.2.0 or higher

Using older versions or different Ruby implementations might work but it\'s not
guaranteed.

#### Postgres
This new API stores all its contents inside a Postgres database.

Version 9.4 or later is recommended because of the heavy reliance on JSON data
types and operators.

#### Redis

Redis is used to exchange messages between CER and the Gremlin indexer application.
Version 4.0 or higher is recommended.

#### Gremlin Server

The API can optionally expose data in a graph via a Gremlin server backed by
Neo4J. More information is provided [here](/docs/07_search_02_gremlin.md).
Example configuration for Gremlin is available in `db/gremlin-config`.

We are currently using Gremlin Server 3.3.3.

### Setup

We provide a setup script that should take care of installing dependencies and
setting up the development & test databases.

First, create a local DB user for the registry:

```
sudo -u <postgres system user> createuser metadataregistry -s
```

Then from the root of the project, simply run

```shell
bin/setup
```

Remember to tweak the `.env.local` file in case the defaults provided
don\'t suit your environment.
For example, if you wish to change the postgres database, use the following
env vars on `.env.local`:

```
POSTGRESQL_ADDRESS=http://my-db-address.db
POSTGRESQL_USERNAME=my_user
POSTGRESQL_PASSWORD=my_super_secret_passwd
POSTGRESQL_DATABASE=metadataregistry_development
```

## Vagrant VM

- first install [virtualbox](https://www.virtualbox.org/) and [vagrant](http://vagrantup.com)
- on the project root:

```shell
vagrant up
vagrant ssh  # enter your vm
```

- Inside the VM shell, run the following only once:

```shell
cd /vagrant
bin/bootstrap
```

- If you want to start using right after the `bootstrap`:

```
source ~/.bashrc
cd ~/metadataregistry
rspec  # run tests
```

- Thats it! The flow for working on vagrant is:
    - run the VM: `vagrant up`
    - log into the machine: `vagrant ssh`
    - run anything on the vm: `cd metadataregistry; bin/rackup -o 0.0.0.0` for example.
    - exit the VM shell as usual
    - shutdown the VM: `vagrant halt`


On the VM, the project will be placed on the home folder, linked with your host vm.
I.e.: any changes you make on the host using your editor for example, are immediately reflected on the VM.
You can access the server (running inside the vm) on the host machine as if it were running locally (localhost:9292)


## Basic usage

The API is built using the [Grape framework](https://github.com/ruby-grape/grape),
so it\'s a little bit different than a regular Rails or Sinatra based application.
However, it\'s still a Rack application, so you can run

```shell
bin/rackup
```

and a development server should start on port 9292 of your local machine.

To access an interactive ruby shell, run:

```shell
bin/console
```

## Running the tests

Tests are written using RSpec. If you want to run the whole test suite, execute

```
bin/rspec -f d
```

This will display the test results using a nicely formatted output.
