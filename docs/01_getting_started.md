## Getting started

Let's see what steps we need to take in order to get our first envelope
published using the new API endpoints.

_Note: these steps only apply to Unix based systems and MacOS X. Steps for Windows systems
will be added later._

### 1. Generate an RSA key pair

First of all, we'll need to create an **RSA** public/private key pair (assuming no
previous keys already exist).

For more information about public and private keys please read [this article](https://medium.com/@vrypan/explaining-public-key-cryptography-to-non-geeks-f0994b3c2d5) or read about [public key cryptography on Wikipedia](https://en.wikipedia.org/wiki/Public-key_cryptography)

#### Using ssh-keygen:

- For linux users: `ssh-keygen` is available on your terminal
- For windows users: a good alternative is to install [git for windows](https://github.com/msysgit/msysgit/releases). [Check here for more info.](http://stackoverflow.com/questions/28183336/ssh-key-generation-for-git-on-windows-8/28186307#28186307)
- For Mac users: `ssh-keygen` is available, but keep aware of versions:
  - update your MacOS to El Captain (10.11) or later
  - If you don't want to update, you should update at least OpenSSH. To do that, follow the instructions here: https://mochtu.de/2015/01/07/updating-openssh-on-mac-os-x-10-10-yosemite/

From your system shell, just run

```shell
ssh-keygen -t rsa
```

By default, this will generate a couple of files:

- `~/.ssh/id_rsa` contains the private part of the key
- `~/.ssh/id_rsa.pub` contains the public part of the key

For converting the public key to the pem format:

```shell
ssh-keygen -f ~/.ssh/id_rsa.pub -e -m pem
```

#### Using openssl:

```bash
# Generate a 2048 bit RSA Key
openssl genrsa -des3 -out private.pem 2048

# Export the RSA Public Key to a PEM File
openssl rsa -in private.pem -outform PEM -pubout -out public.pem
```

`private.pem` and `public.pem` as expected has your keys.
Add them to a suitable place (probably `~/.ssh/`)

If you already have RSA keys, you should just convert your key to PEM format:

```shell
ssh-keygen -f ~/.ssh/id_rsa.pub -e -m pem
```

### 2. Generate a signed token from our content

Once we have a proper set of RSA keys, it's time to build our first envelope.
But before we can do that it's worth mentioning that the API
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
  "registry_metadata": {
    "identity": {
      "signer": "Alpha Node <administrator@example.org>",
      "submitter": "John Doe <john@example.org>",
      "submitter_type": "user"
    },
    "terms_of_service": {
      "submission_tos": "http://example.org/tos"
    },
    "digital_signature": {
      "key_location": ["http://example.org/pubkey"]
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

PS: If you are using a custom lib or any other language,
keep in mind that since you are using a **RSA** key, you should encode using
the **RS256** hash algorithm. For example:

```ruby
JWT.encode(json_content, rsa_private_key, 'RS256')
# or equivalent on different languages
```

### 3. Build the envelope request

The most usual format for an envelope is going to be JSON, so that's what we'll
be using for this example request.

A typical publishing envelope request requires the following fields to be sent:

- `envelope_type`: Defines the type of the envelope. For now, the only accepted
  value is `resource_data`
- `envelope_version`: The version that our envelope is using
- `envelope_community`: The community for this envelope. All envelopes are organized on communities, each of these has different resource schemas. Ex: `ce_registry` and `learning_registry`.
- `resource`: The JWT encoded content we just generated
- `resource_format`: Internal format of our resource. Can be `json` or `xml`
- `resource_encoding`: The algorithm used to encode the resource. In our case
  it's `jwt`, but in the future we could support other encodings, such as `MIME`
- `resource_public_key`: the **public key in the PEM format** whose private part was used to sign the
  resource. This is strictly needed for signature validation purposes. In your public key you should replace end lines with `\n` symbols, and then paste the public key into the request.

Using the above information, our final publish envelope request would look like
this:

```json
{
  "envelope_type": "resource_data",
  "envelope_version": "1.0.0",
  "envelope_community": "learning_registry",
  "resource": "<encoded resource>",
  "resource_format": "json",
  "resource_encoding": "jwt",
  "resource_public_key": "-----BEGIN RSA PUBLIC KEY-----\nMIIBCgKCAQEA35JBqCEfCFMuplTm0NvQxnvwAzQHVEUD8yvn6u3uVkKuX9oOPh4r\nKw9j1D7wNK/70oEsvnuBwNWHT7jXdd1bMDiN0d/TPLFllA2u8+Rr8enXU/1WpxH1\nyQxF7lcHyrl07YJ5B3V4PfgdTOR5vm8PB1UxiTNyrdmdeJ0POhphudXUIJF7HGog\ncO3T12fASzjvBod4GQmaMg6Ffm875rw7f5ASPrslbmuQfwDI3wvEQw/Br4Tw0ltV\nGCxbsjCLymnoHS3TNiK9h8v+nGWrz+kz15RMiMkiKNI3CWYph9SANlkHNYycWTP+\nUNUbpT4mqbXSXJN05SdSAJuQotc0SN7/4QIDAQAB\n-----END RSA PUBLIC KEY-----"
}
```

Please note that you should replace the contents of resouce and resource_public_key fields with data you generated on the previous steps.

Let's store this JSON snippet in a file called `envelope.json`, so we can
reference it in the next step.

### 4. Call the `publish resource` endpoint

The last step involves calling the actual endpoint with our request data so that
the envelope is finally published on our development Metadata Registry node.

Since we always work in a community context, our endpoints follow the pattern:

```
/<community-name>/<endpoint>
```

So for publishing an envelope for the \"ce-registry\" community,
you would use `/ce-registry/resources`.

For convenience's sake a default community can be configured both globally and
per host. This allows us to drop the community part from the URL.

```
/resources
```

Since this is a REST API, we can use typical tools like cURL or HTTPie.

#### Using HTTPie

```shell
http POST :9292/learning-registry/resources < envelope.json
```

#### Using cURL

```shell
curl -X POST http://localhost:9292/learning-registry/resources -d @envelope.json \
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
    "registry_metadata": {
      "digital_signature": {
        "key_location": ["http://example.org/pubkey"]
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
  "envelope_community": "learning_registry",
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
        "url": "/learning-registry/envelopes/8abe3a93-9469-4ef3-855f-b59348820cc6"
      }
    ]
  },
  "resource": "<encoded resource>",
  "resource_encoding": "jwt",
  "resource_format": "json",
  "created_at": "2016-04-28 14:34:56 UTC",
  "updated_at": "2016-04-28 14:34:56 UTC",
  "deleted_at": null
}
```

Please refer to the additional resources below to learn more about the API
endpoints, as well as how to perform other envelope operations such as update or
delete.

You can check a [CE/Registry walkthrough](/docs/02_ce-registry_walkthrough.md).
Most of what's there should apply for most communities, except some `resource`
specific details.

Tip: to preview JSON responses in browser in a nicely readable way, install an extension for Google Chrome: [JSONView](https://chrome.google.com/webstore/detail/jsonview/chklaanhfefbnpoihckbnefhakgolnmc?hl=en)
