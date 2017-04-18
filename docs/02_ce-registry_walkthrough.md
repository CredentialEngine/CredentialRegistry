# CE/Registry Resources Walkthrough

Currently our API always uses json to send and receive data, so always use
the `Content-Type: application/json` header on your requests.

We share resources on the `metadataregistry` by sending `envelopes` of data.

The envelopes are organized in "communities", the CE/Registry is a community.

For accessing info about the available communities you can use:

```
GET /info
```

Almost all resources on our system have an `info` endpoint so you can access
api-docs and metadata about that resource. So, for example, to access info
about the 'ce-registry' community you can do:

```
GET /ce-registry/info
```

Each `envelope` has a well defined structure which contains an encoded resource.

These resources are [json-ld](http://json-ld.org/) objects, which has
a [json-schema](http://json-schema.org/) definition. They are encoded,
on the envelope, using [JWT](https://jwt.io/), so you will need and
RSA key pair.

Lets go step-by-step on how to deliver our first envelope of data for the
'credential_registry' community.

## 1 - Resource

As said before, the resources are community specific and they have a
corresponding json-schema.
The current schema definitions for 'ce-registry' are:

- Organization:
    - [schema definition](http://lr-staging.learningtapestry.com/schemas/ce_registry/organization)
    - get schema from api: `GET /schemas/ce_registry/organization`
    - [sample data](/docs/samples/cer-organization.json)

- Credential:
    - [schema definition](http://lr-staging.learningtapestry.com/schemas/ce_registry/credential)
    - get schema from api: `GET /schemas/ce_registry/credential`
    - [sample data](/docs/samples/cer-credential.json)


The resource json-ld usually uses a context as the following:

```json
"@context": {
  "schema": "http://schema.org/",
  "dc": "http://purl.org/dc/elements/1.1/",
  "dct": "http://dublincore.org/terms/",
  "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
  "rdfs": "http://www.w3.org/2000/01/rdf-schema#",
  "ceterms": "http://purl.org/ceterms/terms/"
}
```

The valid `@type` entries are:
  - For the `organization` json-schema:
    - `ceterms:CredentialOrganization`

  - For the `credential` json-schema:
    - `ceterms:Credential`
    - `ceterms:Badge`
    - `ceterms:DigitalBadge`
    - `ceterms:OpenBadge`
    - `ceterms:Certificate`
    - `ceterms:ApprenticeshipCertificate`
    - `ceterms:JourneymanCertificate`
    - `ceterms:MasterCertificate`
    - `ceterms:Certification`
    - `ceterms:Degree`
    - `ceterms:AssociateDegree`
    - `ceterms:BachelorDegree`
    - `ceterms:DoctoralDegree`
    - `ceterms:ProfessionalDoctorate`
    - `ceterms:ResearchDoctorate`
    - `ceterms:MasterDegree`
    - `ceterms:Diploma`
    - `ceterms:GeneralEducationDevelopment`
    - `ceterms:SecondarySchoolDiploma`
    - `ceterms:License`
    - `ceterms:MicroCredential`
    - `ceterms:QualityAssuranceCredential`

For simplicity, on this example we are going to use the minimal definition bellow:

- create 'resource.json' with the content:
```
{
  "@context": {
    "schema": "http://schema.org/",
    "dc": "http://purl.org/dc/elements/1.1/",
    "dct": "http://dublincore.org/terms/",
    "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
    "rdfs": "http://www.w3.org/2000/01/rdf-schema#",
    "ceterms": "http://purl.org/ceterms/terms/"
  },
  "@type": "ceterms:CredentialOrganization",
  "ceterms:ctid": "urn:ctid:e0959e98-78fd-495e-9189-ed7d3dafc70c",
  "schema:name": "Sample Org"
}
```

## 2 - Encode with JWT

- The first step is to have a **RSA** key pair, if you don't then check the [README](/README.md#1-generate-a-rsa-key-pair) for info on how to do this.
- You can use any JWT lib to encode, but if you have a ruby environment we provide a script `bin/jwt_encode`. You can just run:
   ```shell
   ruby bin/jwt_encode resource.json ~/.ssh/id_rsa
   ```
   The output will contain an encoded string for our resource.
- If you are using another lib/language keep in mind that since you are using a **RSA** key, you should encode using a compatible hash algorithm, for example **RS256**.

## 3 - Generate the envelope

The `envelope` follows this structure:

```
{
  "envelope_type": "resource_data",
  "envelope_version": "1.0.0",
  "envelope_community": "ce_registry",
  "resource": /* JWT encoded resource from the previous step */,
  "resource_format": "json",
  "resource_encoding": "jwt",
  "resource_public_key": /* Public key in PEM format, e.g. the content from '~/.ssh/id_rsa.pem', be aware of line breaks */
}
```

Where:
- `envelope_type`: Defines the type of the envelope. For now, the only accepted
value is `resource_data`
- `envelope_version`: The version that our envelope is using
- `envelope_community`: The community for this envelope. All envelopes are organized on communities, each of these has different resource schemas. In this case we use `ce_registry`.
- `resource`: The JWT encoded content we just generated
- `resource_format`: Internal format of our resource. Can be `json` or `xml`
- `resource_encoding`: The algorithm used to encode the resource. In our case
it's `jwt`, but in the future we could support other encodings, such as `MIME`
- `resource_public_key`: the _public key in the PEM format_ whose private part was used to sign the
resource. This is strictly needed for signature validation purposes

For our example:

- create an 'envelope.json' with:

```json
{
  "envelope_type": "resource_data",
  "envelope_version": "1.0.0",
  "envelope_community": "ce_registry",
  "resource": "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJAY29udGV4dCI6eyJzY2hlbWEiOiJodHRwOi8vc2NoZW1hLm9yZy8iLCJkYyI6Imh0dHA6Ly9wdXJsLm9yZy9kYy9lbGVtZW50cy8xLjEvIiwiZGN0IjoiaHR0cDovL2R1YmxpbmNvcmUub3JnL3Rlcm1zLyIsInJkZiI6Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiLCJyZGZzIjoiaHR0cDovL3d3dy53My5vcmcvMjAwMC8wMS9yZGYtc2NoZW1hIyIsImN0ZGwiOiJbQ1RJIE5hbWVzcGFjZSBOb3QgRGV0ZXJtaW5lZCBZZXRdIn0sIkB0eXBlIjoiY3RkbDpPcmdhbml6YXRpb24iLCJjdGRsOmN0aWQiOiJ1cm46Y3RpZDplMDk1OWU0Mi03ODlkLTQ5NWUtOTE4OS1lZDdkM2RhZmM3MDIiLCJjdGRsOm5hbWUiOiJTYW1wbGUgT3JnIn0.xERgX_wl19xq9lIRkTtDAlWl_Mges8XjJo_nA152RoIyUGcbYkNMd7eBv3aopUWTmBRXj9tXavX5UC_jBZ80AfvjMrgxULbwhS5HVf4o_lp2IK5ZaP6h0WiYHvaBz-dR8VYnQnNS2sTadRMJBZNzym0crwsiAoxfVR4HOBvz0JbBY8b2CSBvx72-u5DrOPWi8ueea3LFUlq1ns7UlZknt4Rgz5BuyQwUwOFMjD_5dyD-4LDMf-jv1F6dGCSMzrghxXuXBb3gZGd5nej7p7HwFHs18Zlw1M4zyyMC7FgORHh5NLxku36M3CwjtiHltaB8iuhPQbtNJ28bbAGhJ-iGzA",
  "resource_format": "json",
  "resource_encoding": "jwt",
  "resource_public_key": "-----BEGIN RSA PUBLIC KEY-----\nMIIBCgKCAQEA35JBqCEfCFMuplTm0NvQxnvwAzQHVEUD8yvn6u3uVkKuX9oOPh4r\nKw9j1D7wNK/70oEsvnuBwNWHT7jXdd1bMDiN0d/TPLFllA2u8+Rr8enXU/1WpxH1\nyQxF7lcHyrl07YJ5B3V4PfgdTOR5vm8PB1UxiTNyrdmdeJ0POhphudXUIJF7HGog\ncO3T12fASzjvBod4GQmaMg6Ffm875rw7f5ASPrslbmuQfwDI3wvEQw/Br4Tw0ltV\nGCxbsjCLymnoHS3TNiK9h8v+nGWrz+kz15RMiMkiKNI3CWYph9SANlkHNYycWTP+\nUNUbpT4mqbXSXJN05SdSAJuQotc0SN7/4QIDAQAB\n-----END RSA PUBLIC KEY-----"
}
```

- You can check the `envelope` schema definition on:
    - [schema definition](http://lr-staging.learningtapestry.com/schemas/envelope)
    - get schema from api: `GET /schemas/envelope`


## 4 - POST to the API:


```
POST /ce_registry/envelopes < envelope.json
```

This should return a `201 created` response with the decoded resource in it.

## 5 - Errors:

If any validation error occurs you will receive an `422 unprocessable_entity`
with a json payload containing a list of validation errors.

```
{
  "errors": [/* list of validation error messages */],
  "json_schema": [ /* list of relevant json-schemas used for this resource validation */]
}
```

Whenever an error happens, you should receive a descriptive error message. If
that is not the case, please contact us.

## 6 - Retrieve the resource:

To retrieve a resource, simply use the resource's ID.

```
GET /ce_registry/resources/urn:ctid:e0959e98-78fd-495e-9189-ed7d3dafc70c

# or again, simply omit the community name if you want to use the default

GET /resources/urn:ctid:e0959e98-78fd-495e-9189-ed7d3dafc70c
```

## 7 - Updating the resource:

To update the resource you have to `PUT` an updated resource in an `envelope`.

```
GET /ce_registry/resources/urn:ctid:e0959e98-78fd-495e-9189-ed7d3dafc70c < envelope.json

# or again, simply omit the community name if you want to use the default

GET /resources/urn:ctid:e0959e98-78fd-495e-9189-ed7d3dafc70c < envelope.json
```

## 8 - Deleting Envelopes

In order to delete a resource, make a `DELETE` request with an envelope
following this specification in the payload:

```json
{
  "envelope_community":"ce_registry",
  "delete_token":"eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJkZWxldGUiOnRydWV9.CEdAcsR-qKrjmwXHdxxJWsrH2zltQzhyfv8R0Adm08ckWpXNw4ZDEzJFCMP8QP4p_Qaun5rmK6IoFXA_xtTJ_xGVtLEVXt5ajpgyUubbgVj33nUxxPhCWhjHWssbdw6wYIUl2Ny0nKU5jSDt-eiJ3bhAtykFzi3teqqM3sl8OQEMPwxSrxTevJxpFcT0874Ymb5_8bjQ_GygqvD_dx6z3vy9UkS6ZffYb_CCYub1u-nFD9kHb7mhLZwAuOEA5DOGJT4pflK8rdAJUz9OwyMAO4yRK2ZYvjPBNkQPyNIBzescGTI8P7FkoE2JRVsPwuh5wncnSmE7XLsjr84pioAWkQ",
  "delete_token_format":"json",
  "delete_token_encoding":"jwt",
  "delete_token_public_key":"-----BEGIN PUBLIC KEY-----\nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAp32A8vGxAxwgVM1pLNUb\nPH0WPB1tX6ASoyOcXvCuW0cTHGdxnbYY+3TbLmjBQSUiznUXWGO3eqTK9YU8kKAo\nApXtOZNwjBLxp5K3xZNjGv9mryqWiGN4IPQWvTR2lvLmPpNOPEhJETL9Hq9Lzzzk\nV0R/bdd2+5WxF83gV9tSH1FfmrEF5RZk8QoLCxdWxmymwF69M6AjV8KQnbZJazYK\n7dbei60Bs8Hy8OV23ehiW5kvUt7DUPBKxVtHvTySE2Ntmd/0Ib/s2bCIfZGJv2ts\nMerRRr665jRCQ43xU043qSPBLUa7TlWWiyqi5UUiWAlyPHXtxaaDJUajIYJD/1os\nCwIDAQAB\n-----END PUBLIC KEY-----\n"
}
```

where:

- `envelope_community`: 'ce_registry'
- `delete_token`: is **any** json encoded in JWT using your key pair. This is
                  used to guarantee that it's you who are sending the request
                  (only the bearer of the private key, can provide a valid
                  token). For example: you can use the json `{"delete": true}`
- `delete_token_format`: only `json` for now
- `delete_token_encoding`: only `jwt` for now
- `delete_token_public_key`: It has to be the **same key** used to create the
                             resource, i.e: only the creator can delete. A
                             different key would cause a
                             `Signature verification raised` error.

Regarding the responses:

- `204 No Content` is the success response, indicating that this resource was
  successfully deleted.
- `422 Unprocessable Entity` indicates validation errors, check the body for the messages.

```
http DELETE /ce_registry/resources/urn:ctid:e0959e98-78fd-495e-9189-ed7d3dafc70c < delete_envelope.json

# or again, simply omit the community name if you want to use the default

http DELETE /resources/urn:ctid:e0959e98-78fd-495e-9189-ed7d3dafc70c < delete_envelope.json
```

## 9 - Get a list of envelopes

In addition to the `/resources` endpoint, the API offers an `/envelopes`
endpoint. You can use it to retrieve a list of all envelopes (and their
embedded resources).

```
GET /ce-registry/envelopes
```

 Use the `page` and `per_page` params to control pagination.

 The pagination info is included in the `Link` header.

 ```

Link: <https://example-url.com/ce-registry/envelopes?page=3&per_page=100>; rel="next",
  <https://example-url.com/ce-registry/envelopes?page=50&per_page=100>; rel="last"
```

The possible rel values are:

- next 	: The link relation for the immediate next page of results.
- last 	: The link relation for the last page of results.
- first :	The link relation for the first page of results.
- prev  :	The link relation for the immediate previous page of results.


## 10 - Requesting deleted envelopes

Since deleting an envelope is purely logical, i.e. envelopes are only
marked as deleted, you can retrieve deleted records using query parameters.

Add these parameters to any API request to include the deleted records into the
result set:

- `?include_deleted=true` - returns all records including deleted ones
- `?include_deleted=only` - returns only deleted records

For example:
`GET /ce-registry/envelopes?include_deleted=true` - should return a list of envelopes including the deleted ones.

These parameters also work with search requests. [Read more about searching envelopes](/docs/07_search.md).

## 11 - Configuring the default community

A default community can be configured both globally ([See `db/seeds.rb`](../blob/master/db/seeds.rb))
as well as per server host ([See `config/envelope_communities.json`](../blob/a7e26d4542e0861e1b62fcdcd510819be510e378/config/envelope_communities.json)).

-----

For more info check our swagger docs and the json-schemas.

If you have any questions or suggestion, please open an [issue on
GitHub](https://github.com/CredentialEngine/CredentialRegistry/issues).
