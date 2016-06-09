# Learning Registry API version 2.0

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
- [Requirements](#requirements)
    - [Ruby](#ruby)
    - [Postgres](#postgres)
- [Installation](#installation)
- [Basic usage](#basic-usage)
- [Getting started](#getting-started)
- [Resources](#resources)
    - [Swagger documentaion](#swagger-documentation)
    - [Postman collection](#postman-collection)
- [Running the tests](#running-the-tests)
- [License](#license)
- [Credits](#credits)

## Introduction
This project comprises the new implementation of the Learning Registry API,
using more a widely-used database and providing a more developer-friendly,
REST-oriented environment.

### Project Status
This project is currently in testing phase. It is not for production use at this time. A running developer testbed node is located at lr-staging.learningtapestry.com

## Requirements

### Ruby
We recommend using one of the following Ruby platforms:

* MRI version 2.3.1 or higher
* JRuby version 9.1.2.0 or higher

Using older versions or different Ruby implementations might work but it's not
guaranteed.

### Postgres
This new API stores all its contents inside a Postgres database.

Version 9.4 or later is recommended because of the heavy reliance on JSON data
types and operators.


## Installation

We provide a setup script that should take care of installing dependencies and
setting up the development & test databases.

From the root of the project, simply run

```shell
ruby bin/setup
```

Remember to tweak the `config/database.yml` file in case the defaults provided
don't suit your environment.

## Basic usage

The API is built using the [Grape framework](https://github.com/ruby-grape/grape),
so it's a little bit different than a regular Rails or Sinatra based application.
However, it's still a Rack application, so you can run

```shell
ruby bin/rackup
```

and a development server should start on port 9292 of your local machine.

## Getting started

Let's see what steps we need to take in order to get our first envelope
published into the Learning Registry using the new API endpoints.

_Note: these steps only apply to Unix based systems. Steps for Windows systems
will be added later._

### 1. Generate a RSA key pair
First of all, we'll need to create a RSA public/private key pair (assuming no
previous keys already exist).

From your system shell, just run

```shell
ssh-keygen -t rsa
```

By default, this will generate a couple of files:

* `~/.ssh/id_rsa` contains the private part of the key
* `~/.ssh/id_rsa.pub` contains the public part of the key

### 2. Generate a signed token from our content
Once we have a proper set of RSA keys, it's time to build our first envelope.
But before we can do that it's worth mentioning that the new Learning Registry
endpoints use [JSON Web Tokens](https://jwt.io/) for encoding and decoding
envelopes. This means that we'll need to locally sign our content using the
previously generated RSA keys prior to building the envelope.

Let's create a new file called `resource.json` that will store the contents we
want to publish in JSON format:

```json
{
    "url": "http://example.org/activities/16/detail",
    "name": "The Constitution at Work",
    "description": "In this activity students will analyze envelopes ...",
    "learning_registry_metadata": {
        "identity": {
            "signer": "Alpha Node <administrator@example.org>",
            "submitter": "John Doe <john@example.org>",
            "submitter_type": "user"
        },
        "terms_of_service": {
            "submission_tos": "http://example.org/tos"
        },
        "digital_signature": {
            "key_location": [
                "http://example.org/pubkey"
            ]
        },
        "payload_placement": "inline"
    }
}
```

Any JWT compliant library would be valid for encoding our resource but, since
we've already installed a Ruby environment, we can leverage the tools provided
by the project itself. The `bin/jwt_encode` script will come in handy for this
purpose, because it allows us to easily encode and sign resources using JWT.

Its usage is as follows:

```shell
ruby bin/jwt_encode RESOURCE PRIVATE_KEY
```

Knowing that, we can generate our token by providing our own values:

```shell
ruby bin/jwt_encode resource.json /home/user/.ssh/id_rsa
```

The displayed output should be the JWT encoded representation of the contents
inside `resource.json`, signed with the provided private key.

```
eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJ1cmwiOiJodHRwOi8vZXhhbXBsZS5vcmcvYWN0aXZpdGllcy8xNi9kZXRhaWwiLCJuYW1lIjoiVGhlIENvbnN0aXR1dGlvbiBhdCBXb3JrIiwiZGVzY3JpcHRpb24iOiJJbiB0aGlzIGFjdGl2aXR5IHN0dWRlbnRzIHdpbGwgYW5hbHl6ZSBlbnZlbG9wZXMgLi4uIiwibGVhcm5pbmdfcmVnaXN0cnlfbWV0YWRhdGEiOnsiaWRlbnRpdHkiOnsic2lnbmVyIjoiQWxwaGEgTm9kZSA8YWRtaW5pc3RyYXRvckBleGFtcGxlLm9yZz4iLCJzdWJtaXR0ZXIiOiJqb2huIGRvZSA8am9obkBleGFtcGxlLm9yZz4iLCJzdWJtaXR0ZXJfdHlwZSI6InVzZXIifSwidGVybXNfb2Zfc2VydmljZSI6eyJzdWJtaXNzaW9uX3RvcyI6Imh0dHA6Ly9leGFtcGxlLm9yZy90b3MifSwiZGlnaXRhbF9zaWduYXR1cmUiOnsia2V5X2xvY2F0aW9uIjpbImh0dHA6Ly9leGFtcGxlLm9yZy9wdWJrZXkiXX0sInBheWxvYWRfcGxhY2VtZW50IjoiaW5saW5lIn19.h2R2pr29jTqVP0HWJTZYozjTJ7mbqudJNRzEpVH6EmE3GAP9Q46DTqIJKsbEaTH6ceLdAJOCWisks13o0XPF4n-cXJM0xR8yvLATrYlFBE_WlgD6q0Gi8CneTdpR_Jf5aYgZCf0ayG_q3LPCOYyRXeS53FGn434aOoN1rbAzq51LwUGIcYwST2L4MorhqV31_l8rmX2v8R2qY_NUC4zGJvAn8CW1EAwOHstoJQ-5deJEPOSx7WuWFtadP-ec8DwxEDauiPnyQ7FRmtYtBHTaDh8vT1uV7TcVXYcF4dBs5B0AWtuJajjhZYsQL5uDdunzxRRn6Dfr6g5-APESbIOiVQ
```

### 3. Build the envelope request
The most usual format for an envelope is going to be JSON, so that's what we'll
be using for this example request.

A typical publishing envelope request requires the following fields to be sent:

* `envelope_type`: Defines the type of the envelope. For now, the only accepted
value is `resource_data`
* `envelope_version`: The version that our envelope is using
* `resource`: The JWT encoded content we just generated
* `resource_format`: Internal format of our resource. Can be `json` or `xml`
* `resource_encoding`: The algorithm used to encode the resource. In our case
it's `jwt`, but in the future we could support other encodings, such as `MIME`
* `resource_public_key`: the public key whose private part was used to sign the
resource. This is strictly needed for signature validation purposes

Using the above information, our final publish envelope request would look like
this:

```json
{
  "envelope_type": "resource_data",
  "envelope_version": "1.0.0",
  "resource": "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJ1cmwiOiJodHRwOi8vZXhhbXBsZS5vcmcvYWN0aXZpdGllcy8xNi9kZXRhaWwiLCJuYW1lIjoiVGhlIENvbnN0aXR1dGlvbiBhdCBXb3JrIiwiZGVzY3JpcHRpb24iOiJJbiB0aGlzIGFjdGl2aXR5IHN0dWRlbnRzIHdpbGwgYW5hbHl6ZSBlbnZlbG9wZXMgLi4uIiwibGVhcm5pbmdfcmVnaXN0cnlfbWV0YWRhdGEiOnsiaWRlbnRpdHkiOnsic2lnbmVyIjoiQWxwaGEgTm9kZSA8YWRtaW5pc3RyYXRvckBleGFtcGxlLm9yZz4iLCJzdWJtaXR0ZXIiOiJqb2huIGRvZSA8am9obkBleGFtcGxlLm9yZz4iLCJzdWJtaXR0ZXJfdHlwZSI6InVzZXIifSwidGVybXNfb2Zfc2VydmljZSI6eyJzdWJtaXNzaW9uX3RvcyI6Imh0dHA6Ly9leGFtcGxlLm9yZy90b3MifSwiZGlnaXRhbF9zaWduYXR1cmUiOnsia2V5X2xvY2F0aW9uIjpbImh0dHA6Ly9leGFtcGxlLm9yZy9wdWJrZXkiXX0sInBheWxvYWRfcGxhY2VtZW50IjoiaW5saW5lIn19.h2R2pr29jTqVP0HWJTZYozjTJ7mbqudJNRzEpVH6EmE3GAP9Q46DTqIJKsbEaTH6ceLdAJOCWisks13o0XPF4n-cXJM0xR8yvLATrYlFBE_WlgD6q0Gi8CneTdpR_Jf5aYgZCf0ayG_q3LPCOYyRXeS53FGn434aOoN1rbAzq51LwUGIcYwST2L4MorhqV31_l8rmX2v8R2qY_NUC4zGJvAn8CW1EAwOHstoJQ-5deJEPOSx7WuWFtadP-ec8DwxEDauiPnyQ7FRmtYtBHTaDh8vT1uV7TcVXYcF4dBs5B0AWtuJajjhZYsQL5uDdunzxRRn6Dfr6g5-APESbIOiVQ",
  "resource_format": "json",
  "resource_encoding": "jwt",
  "resource_public_key": "-----BEGIN PUBLIC KEY-----\nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAyLYNBXiEcTF9OaSmmJ8r\nlpd1KEdufmvhpt8MlUTWnOEJr0CrWwvR/jMJ5B9CGMcu83Mcb214hcynoAxPrJJS\nL/pLUtY7xhYFILXDcXu/+Rl3I7km3mXzDc7uuD3DK84Ed70QsFkIR9BzX1VGwDQx\nJEKq4GNljXTV0QvAuiQiVFSFzPh4p9lDaUzGGhzDLiTNiS6Icq6bqc/mUNApRWNY\nlF13PDWksGGyUlhgFP3FFOPj2qYi4FDf8ToHYdOziFAYTtkSQjUvRhkz+xDVSR6p\now742ZZs078Ubyin01Qe9qTbZhby6wuXoIBHfch9/QvlGKLVxcd4utii1A8Q/IGl\nTwIDAQAB\n-----END PUBLIC KEY-----\n"
}
```

Let's store this JSON snippet in a file called `envelope.json`, so we can
reference it in the next step.

### 4. Call the `publish envelope` endpoint
The last step involves calling the actual endpoint with our request data so that
the envelope is finally published on our development Learning Registry node.

Since this is a REST API, we can use typical tools like cURL or HTTPie.

#### Using HTTPie
```shell
http POST :9292/api/envelopes < envelope.json
```

#### Using cURL
```shell
curl -X POST http://localhost:9292/api/envelopes -d @envelope.json \
--header "Content-Type: application/json"
```

The response should look quite similar to this:

```
HTTP/1.1 201 Created
Connection: Keep-Alive
Content-Length: 2031
Content-Type: application/json
Date: Thu, 28 Apr 2016 14:34:56 GMT
Server: WEBrick/1.3.1 (Ruby/2.3.0/2015-12-25)
```

```json
{
    "decoded_resource": {
        "description": "In this activity students will analyze envelopes ...",
        "learning_registry_metadata": {
            "digital_signature": {
                "key_location": [
                    "http://example.org/pubkey"
                ]
            },
            "identity": {
                "signer": "Alpha Node <administrator@example.org>",
                "submitter": "john doe <john@example.org>",
                "submitter_type": "user"
            },
            "payload_placement": "inline",
            "terms_of_service": {
                "submission_tos": "http://example.org/tos"
            }
        },
        "name": "The Constitution at Work",
        "url": "http://example.org/activities/16/detail"
    },
    "envelope_id": "8abe3a93-9469-4ef3-855f-b59348820cc6",
    "envelope_type": "resource_data",
    "envelope_version": "1.0.0",
    "node_headers": {
        "created_at": "2016-04-28 14:34:56 UTC",
        "deleted_at": null,
        "resource_digest": "ahjxYnisvhUXj7qaQiJLofar6Vnds9SvpEpkvdhhxRU=",
        "updated_at": "2016-04-28 14:34:56 UTC",
        "versions": [
            {
                "actor": null,
                "created_at": "2016-04-28 14:34:56 UTC",
                "event": "create",
                "head": true,
                "url": "/api/envelopes/8abe3a93-9469-4ef3-855f-b59348820cc6"
            }
        ]
    },
    "resource": "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJ1cmwiOiJodHRwOi8vZXhhbXBsZS5vcmcvYWN0aXZpdGllcy8xNi9kZXRhaWwiLCJuYW1lIjoiVGhlIENvbnN0aXR1dGlvbiBhdCBXb3JrIiwiZGVzY3JpcHRpb24iOiJJbiB0aGlzIGFjdGl2aXR5IHN0dWRlbnRzIHdpbGwgYW5hbHl6ZSBlbnZlbG9wZXMgLi4uIiwibGVhcm5pbmdfcmVnaXN0cnlfbWV0YWRhdGEiOnsiaWRlbnRpdHkiOnsic2lnbmVyIjoiQWxwaGEgTm9kZSA8YWRtaW5pc3RyYXRvckBleGFtcGxlLm9yZz4iLCJzdWJtaXR0ZXIiOiJqb2huIGRvZSA8am9obkBleGFtcGxlLm9yZz4iLCJzdWJtaXR0ZXJfdHlwZSI6InVzZXIifSwidGVybXNfb2Zfc2VydmljZSI6eyJzdWJtaXNzaW9uX3RvcyI6Imh0dHA6Ly9leGFtcGxlLm9yZy90b3MifSwiZGlnaXRhbF9zaWduYXR1cmUiOnsia2V5X2xvY2F0aW9uIjpbImh0dHA6Ly9leGFtcGxlLm9yZy9wdWJrZXkiXX0sInBheWxvYWRfcGxhY2VtZW50IjoiaW5saW5lIn19.h2R2pr29jTqVP0HWJTZYozjTJ7mbqudJNRzEpVH6EmE3GAP9Q46DTqIJKsbEaTH6ceLdAJOCWisks13o0XPF4n-cXJM0xR8yvLATrYlFBE_WlgD6q0Gi8CneTdpR_Jf5aYgZCf0ayG_q3LPCOYyRXeS53FGn434aOoN1rbAzq51LwUGIcYwST2L4MorhqV31_l8rmX2v8R2qY_NUC4zGJvAn8CW1EAwOHstoJQ-5deJEPOSx7WuWFtadP-ec8DwxEDauiPnyQ7FRmtYtBHTaDh8vT1uV7TcVXYcF4dBs5B0AWtuJajjhZYsQL5uDdunzxRRn6Dfr6g5-APESbIOiVQ",
    "resource_encoding": "jwt",
    "resource_format": "json"
}
```

Please refer to the additional resources below to know more about the API
endpoints, as well as how to perform other envelope operations such as update or
delete.

## Resources

### Swagger documentation
The official Swagger documentation describing the API is available at
[http://lr-staging.learningtapestry.com/swagger/index.html](http://lr-staging.learningtapestry.com/swagger/index.html).
It uses [Swagger UI](https://github.com/swagger-api/swagger-ui) to present the
spec in a visually pleasant format, and also allows you to inspect and call the
available endpoints from the staging node.

In addition, an auto-generated Swagger 2.0 specification is always accessible at
[http://localhost:9292/swagger_doc](http://localhost:9292/swagger_doc).

### Postman collection
We also provide a Postman collection that contains the most up to date API
modifications. You can grab it from here:
https://www.getpostman.com/collections/bc38edc491333b643e23

## Running the tests

Tests are written using RSpec. If you want to run the whole test suite, execute

```
bin/rspec -f d
```

This will display the test results using a nicely formatted output.

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
* Software design and implementation (this version): Abraham Sanchez (@aspino), Steve Midgley (@science)

