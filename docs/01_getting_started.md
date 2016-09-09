## Getting started

Let's see what steps we need to take in order to get our first envelope
published using the new API endpoints.

_Note: these steps only apply to Unix based systems. Steps for Windows systems
will be added later._

### 1. Generate a RSA key pair
First of all, we'll need to create a **RSA** public/private key pair (assuming no
previous keys already exist).

#### Using ssh-keygen:

- For linux users: `ssh-keygen` is available on your terminal
- For windows users: a good alternative is to install (git for windows)[https://github.com/msysgit/msysgit/releases]. Check here for more info: http://stackoverflow.com/questions/28183336/ssh-key-generation-for-git-on-windows-8/28186307#28186307
- For Mac users: `ssh-keygen` is available, but keep aware of versions:
    - update your MacOS to El Captain (10.11) or later
    - If you don't want to update, you should update at least OpenSSH. To do that, follow the instructions here: https://mochtu.de/2015/01/07/updating-openssh-on-mac-os-x-10-10-yosemite/

From your system shell, just run

```shell
ssh-keygen -t rsa
```

By default, this will generate a couple of files:

* `~/.ssh/id_rsa` contains the private part of the key
* `~/.ssh/id_rsa.pub` contains the public part of the key

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
eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJ1cmwiOiJodHRwOi8vZXhhbXBsZS5vcmcvYWN0aXZpdGllcy8xNi9kZXRhaWwiLCJuYW1lIjoiVGhlIENvbnN0aXR1dGlvbiBhdCBXb3JrIiwiZGVzY3JpcHRpb24iOiJJbiB0aGlzIGFjdGl2aXR5IHN0dWRlbnRzIHdpbGwgYW5hbHl6ZSBlbnZlbG9wZXMgLi4uIiwicmVnaXN0cnlfbWV0YWRhdGEiOnsiaWRlbnRpdHkiOnsic2lnbmVyIjoiQWxwaGEgTm9kZSA8YWRtaW5pc3RyYXRvckBleGFtcGxlLm9yZz4iLCJzdWJtaXR0ZXIiOiJKb2huIERvZSA8am9obkBleGFtcGxlLm9yZz4iLCJzdWJtaXR0ZXJfdHlwZSI6InVzZXIifSwidGVybXNfb2Zfc2VydmljZSI6eyJzdWJtaXNzaW9uX3RvcyI6Imh0dHA6Ly9leGFtcGxlLm9yZy90b3MifSwiZGlnaXRhbF9zaWduYXR1cmUiOnsia2V5X2xvY2F0aW9uIjpbImh0dHA6Ly9leGFtcGxlLm9yZy9wdWJrZXkiXX0sInBheWxvYWRfcGxhY2VtZW50IjoiaW5saW5lIn19.OJnrgcww5JpOej2vYGvT0XrD45DVEe7atQ2nPIheag-eBqnaswpyg0EMgeFP2w4TOSPIALbJk6alBxNEToA2bKd_Cg8HL5Jo8-Lwa2q2bE63lGx0lWAx2me9yQnbu9ja13UDlAJedgfNmATzmWp-HjUrd6j0hxNx7N6eDDiZRS0mlVzH5MvP49taKlxmei0-5sxYRj-UQqLePXFN5k7L1aQyxjpFXUVzhVNPVqwqeszCjlPXSNOR91TJyqizibIkFymXT8SyFmHDT6wDdFRkuI7jOPMJ1jzw2g41NiA16GkI4_lQi8ZM_MihM9_i4DnOMObfbYvR42CEKdx-dTWOFA
```

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

* `envelope_type`: Defines the type of the envelope. For now, the only accepted
value is `resource_data`
* `envelope_version`: The version that our envelope is using
* `envelope_community`: The community for this envelope. All envelopes are organized on communities, each of these has different resource schemas. Ex: `credential_registry` and `learning_registry`.
* `resource`: The JWT encoded content we just generated
* `resource_format`: Internal format of our resource. Can be `json` or `xml`
* `resource_encoding`: The algorithm used to encode the resource. In our case
it's `jwt`, but in the future we could support other encodings, such as `MIME`
* `resource_public_key`: the **public key in the PEM format** whose private part was used to sign the
resource. This is strictly needed for signature validation purposes


Using the above information, our final publish envelope request would look like
this:

```json
{
  "envelope_type": "resource_data",
  "envelope_version": "1.0.0",
  "envelope_community": "learning_registry",
  "resource": "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJ1cmwiOiJodHRwOi8vZXhhbXBsZS5vcmcvYWN0aXZpdGllcy8xNi9kZXRhaWwiLCJuYW1lIjoiVGhlIENvbnN0aXR1dGlvbiBhdCBXb3JrIiwiZGVzY3JpcHRpb24iOiJJbiB0aGlzIGFjdGl2aXR5IHN0dWRlbnRzIHdpbGwgYW5hbHl6ZSBlbnZlbG9wZXMgLi4uIiwicmVnaXN0cnlfbWV0YWRhdGEiOnsiaWRlbnRpdHkiOnsic2lnbmVyIjoiQWxwaGEgTm9kZSA8YWRtaW5pc3RyYXRvckBleGFtcGxlLm9yZz4iLCJzdWJtaXR0ZXIiOiJKb2huIERvZSA8am9obkBleGFtcGxlLm9yZz4iLCJzdWJtaXR0ZXJfdHlwZSI6InVzZXIifSwidGVybXNfb2Zfc2VydmljZSI6eyJzdWJtaXNzaW9uX3RvcyI6Imh0dHA6Ly9leGFtcGxlLm9yZy90b3MifSwiZGlnaXRhbF9zaWduYXR1cmUiOnsia2V5X2xvY2F0aW9uIjpbImh0dHA6Ly9leGFtcGxlLm9yZy9wdWJrZXkiXX0sInBheWxvYWRfcGxhY2VtZW50IjoiaW5saW5lIn19.OJnrgcww5JpOej2vYGvT0XrD45DVEe7atQ2nPIheag-eBqnaswpyg0EMgeFP2w4TOSPIALbJk6alBxNEToA2bKd_Cg8HL5Jo8-Lwa2q2bE63lGx0lWAx2me9yQnbu9ja13UDlAJedgfNmATzmWp-HjUrd6j0hxNx7N6eDDiZRS0mlVzH5MvP49taKlxmei0-5sxYRj-UQqLePXFN5k7L1aQyxjpFXUVzhVNPVqwqeszCjlPXSNOR91TJyqizibIkFymXT8SyFmHDT6wDdFRkuI7jOPMJ1jzw2g41NiA16GkI4_lQi8ZM_MihM9_i4DnOMObfbYvR42CEKdx-dTWOFA",
  "resource_format": "json",
  "resource_encoding": "jwt",
  "resource_public_key": "-----BEGIN RSA PUBLIC KEY-----\nMIIBCgKCAQEA35JBqCEfCFMuplTm0NvQxnvwAzQHVEUD8yvn6u3uVkKuX9oOPh4r\nKw9j1D7wNK/70oEsvnuBwNWHT7jXdd1bMDiN0d/TPLFllA2u8+Rr8enXU/1WpxH1\nyQxF7lcHyrl07YJ5B3V4PfgdTOR5vm8PB1UxiTNyrdmdeJ0POhphudXUIJF7HGog\ncO3T12fASzjvBod4GQmaMg6Ffm875rw7f5ASPrslbmuQfwDI3wvEQw/Br4Tw0ltV\nGCxbsjCLymnoHS3TNiK9h8v+nGWrz+kz15RMiMkiKNI3CWYph9SANlkHNYycWTP+\nUNUbpT4mqbXSXJN05SdSAJuQotc0SN7/4QIDAQAB\n-----END RSA PUBLIC KEY-----"
}
```

Let's store this JSON snippet in a file called `envelope.json`, so we can
reference it in the next step.

### 4. Call the `publish envelope` endpoint
The last step involves calling the actual endpoint with our request data so that
the envelope is finally published on our development Metadata Registry node.

Since we always work in a community context, our endpoints follow the pattern:

```
/api/<community-name>/<endpoint>
```

So for publishing an envelope for the \"credential-registry\" community,
you would use `/api/credential-registry/envelopes`.

Since this is a REST API, we can use typical tools like cURL or HTTPie.

#### Using HTTPie
```shell
http POST :9292/api/learning-registry/envelopes < envelope.json
```

#### Using cURL
```shell
curl -X POST http://localhost:9292/api/learning-registry/envelopes -d @envelope.json \
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
                "url": "/api/learning-registry/envelopes/8abe3a93-9469-4ef3-855f-b59348820cc6"
            }
        ]
    },
    "resource": "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJ1cmwiOiJodHRwOi8vZXhhbXBsZS5vcmcvYWN0aXZpdGllcy8xNi9kZXRhaWwiLCJuYW1lIjoiVGhlIENvbnN0aXR1dGlvbiBhdCBXb3JrIiwiZGVzY3JpcHRpb24iOiJJbiB0aGlzIGFjdGl2aXR5IHN0dWRlbnRzIHdpbGwgYW5hbHl6ZSBlbnZlbG9wZXMgLi4uIiwibGVhcm5pbmdfcmVnaXN0cnlfbWV0YWRhdGEiOnsiaWRlbnRpdHkiOnsic2lnbmVyIjoiQWxwaGEgTm9kZSA8YWRtaW5pc3RyYXRvckBleGFtcGxlLm9yZz4iLCJzdWJtaXR0ZXIiOiJqb2huIGRvZSA8am9obkBleGFtcGxlLm9yZz4iLCJzdWJtaXR0ZXJfdHlwZSI6InVzZXIifSwidGVybXNfb2Zfc2VydmljZSI6eyJzdWJtaXNzaW9uX3RvcyI6Imh0dHA6Ly9leGFtcGxlLm9yZy90b3MifSwiZGlnaXRhbF9zaWduYXR1cmUiOnsia2V5X2xvY2F0aW9uIjpbImh0dHA6Ly9leGFtcGxlLm9yZy9wdWJrZXkiXX0sInBheWxvYWRfcGxhY2VtZW50IjoiaW5saW5lIn19.h2R2pr29jTqVP0HWJTZYozjTJ7mbqudJNRzEpVH6EmE3GAP9Q46DTqIJKsbEaTH6ceLdAJOCWisks13o0XPF4n-cXJM0xR8yvLATrYlFBE_WlgD6q0Gi8CneTdpR_Jf5aYgZCf0ayG_q3LPCOYyRXeS53FGn434aOoN1rbAzq51LwUGIcYwST2L4MorhqV31_l8rmX2v8R2qY_NUC4zGJvAn8CW1EAwOHstoJQ-5deJEPOSx7WuWFtadP-ec8DwxEDauiPnyQ7FRmtYtBHTaDh8vT1uV7TcVXYcF4dBs5B0AWtuJajjhZYsQL5uDdunzxRRn6Dfr6g5-APESbIOiVQ",
    "resource_encoding": "jwt",
    "resource_format": "json",
    "created_at": "2016-04-28 14:34:56 UTC",
    "updated_at": "2016-04-28 14:34:56 UTC",
    "deleted_at": null
}
```

Please refer to the additional resources below to know more about the API
endpoints, as well as how to perform other envelope operations such as update or
delete.

You can check a [Credential Registry walkthrough](/docs/02_credential_registry_walkthrough.md).
Most of what's there should apply for most communities, except some `resource`
specific details.
