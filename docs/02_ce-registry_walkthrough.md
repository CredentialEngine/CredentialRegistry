# CE/Registry Resources Walkthrough

Currently our API always uses json to send and receive data, so alway use
the `Content-Type: application/json` header on your requests.

We share resources on the `metadataregistry` by sending `envelopes` of data.

The envelopes are organized in "communities", the CE/Registry is a community.

For accessing info about the available communities you can use:

```
GET /api/info
```

almost all resources on our system have an `info` endpoint so you can access
api-docs and metadata about that resource. So, for example, to access info
about the 'ce-registry' community you can do:

```
GET /api/ce-registry/info
```

Each `envelope` has a well defined structure which contains an encoded resource.

These resources are [json-ld](http://json-ld.org/) objects, which has
a [json-schema](http://json-schema.org/) definition. They are encoded,
on the envelope, using [JWT](https://jwt.io/), so you will need and
RSA key pair.

Lets go step-by-step on how to deliver our first envelope of data for the
'credentital_registry' community.

## 1 - Resource

As said before, the resources are community specific and they have a
corresponding json-schema.
The current schema definitions for 'ce-registry' are:

- Organization:
    - [schema definition](http://lr-staging.learningtapestry.com/api/schemas/ce_registry/organization)
    - get schema from api: `GET /api/schemas/ce_registry/organization`
    - [sample data](/docs/samples/cer-organization.json)

- Credential:
    - [schema definition](http://lr-staging.learningtapestry.com/api/schemas/ce_registry/credential)
    - get schema from api: `GET /api/schemas/ce_registry/credential`
    - [sample data](/docs/samples/cer-credential.json)


The resource json-ld usually uses a context as the following:

```json
"@context": {
  "schema": "http://schema.org/",
  "dc": "http://purl.org/dc/elements/1.1/",
  "dct": "http://dublincore.org/terms/",
  "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
  "rdfs": "http://www.w3.org/2000/01/rdf-schema#",
  "ctdl": "[CTI Namespace Not Determined Yet]"
}
```

The valid `@type` entries are:
  - For the `organization` json-schema:
    - `ctdl:Organization`
    - `ctdl:CredentialOrganization`

  - For the `credential` json-schema:
    - `ctdl:Credential`
    - `ctdl:Badge`
    - `ctdl:DigitalBadge`
    - `ctdl:OpenBadge`
    - `ctdl:Certificate`
    - `ctdl:ApprenticeshipCertificate`
    - `ctdl:JourneymanCertificate`
    - `ctdl:MasterCertificate`
    - `ctdl:Certification`
    - `ctdl:Degree`
    - `ctdl:AssociateDegree`
    - `ctdl:BachelorDegree`
    - `ctdl:DoctoralDegree`
    - `ctdl:ProfessionalDoctorate`
    - `ctdl:ResearchDoctorate`
    - `ctdl:MasterDegree`
    - `ctdl:Diploma`
    - `ctdl:GeneralEducationDevelopment`
    - `ctdl:SecondarySchoolDiploma`
    - `ctdl:License`
    - `ctdl:MicroCredential`
    - `ctdl:QualityAssuranceCredential`

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
    "ctdl": "[CTI Namespace Not Determined Yet]"
  },
  "@type": "ctdl:Organization",
  "ctdl:ctid": "urn:ctid:e0959e98-78fd-495e-9189-ed7d3dafc70c",
  "schema:name": "Sample Org"
}
```

## 2 - Encode with JWT

- The first step is to have a **RSA** key pair, if you don't then check the [README](/README.md#1-generate-a-rsa-key-pair) for info on how to do this.
- You can use any JWT lib to encode, but if you have a ruby environment we provide a script at hand on `bin/jwt_encode`. You can just run:

```shell
ruby bin/jwt_encode resource.json ~/.ssh/id_rsa
```

the output will contain an encoded string for our resource.

- If you are using another lib/language keep in mind that since you are using a **RSA** key, you should encode using a compatible hash algorithm, for example **RS256**.

## 3 - Generate the envelope

The `envelope` follow this structure:

```
{
  "envelope_type": "resource_data",
  "envelope_version": "1.0.0",
  "envelope_community": "ce_registry",
  "resource": /* JWT encoded resource from the previous step */,
  "resource_format": "json",
  "resource_encoding": "jwt",
  "resource_public_key": /* Public key in PEM format, the content from '~/.ssh/id_rsa.pem', be aware of line breaks */
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
    - [schema definition](http://lr-staging.learningtapestry.com/api/schemas/envelope)
    - get schema from api: `GET /api/schemas/envelope`


## 4 - POST to the API:


```
POST /api/ce_registry/envelopes < envelope.json
```

This should return a `201 created` response with the decoded resource in it.

## 5 - Errors:

If any validation error occurs you will probably receive an `422 unprocessable_entity`
with a json, on the message body, containing a list of validation errors. i.e:

```
{
  "errors": [/* list of validation error messages */],
  "json_schema": [ /* list of relevant json-schemas used for this resource validation */]
}
```

Whenever a error happens, you should receive a well descriptive message for
the cause. If that doesn't happen please contact us.

## 6 - Retrieve the resource:

On the success response above you can check the `envelope_id` attribute,
you can use this to retrieve or update the resource. For example:

- if the returned json contains:
```
"envelope_id": "88569f57-3d34-4ba2-9219-24883fdc2fec"
```

- retrieve using:

```
GET /api/ce-registry/envelopes/88569f57-3d34-4ba2-9219-24883fdc2fec
```

## 7 - Updating the resource:

On the POST you could have also passed an 'envelope_id' directly. If you provide a param
`update_if_exists=true` then the system will perform an upsert (i.e: if exists update, else insert) using the provided id.

```
POST /api/ce-registry/envelopes?update_if_exists=true < changed_resource_with_id.json
```

## 8 - Get a list of envelopes

```
GET /api/ce-registry/envelopes
```

 Use the `page` and `per_page` params to control pagination.

 The pagination info is included in the `Link` header.

 ```

Link: <https://example-url.com/api/ce-registry/envelopes?page=3&per_page=100>; rel="next",
  <https://example-url.com/api/ce-registry/envelopes?page=50&per_page=100>; rel="last"
```

The possible rel values are:

- next 	: The link relation for the immediate next page of results.
- last 	: The link relation for the last page of results.
- first :	The link relation for the first page of results.
- prev  :	The link relation for the immediate previous page of results.


## 9 - Deleting Envelopes

For deleting envelopes we use:

```
PUT /api/ce-registry/envelopes < delete_envelope.json
```

The usage of 'PUT' it's because we are actually replacing the document
by a "marked as deleted" version, i,e: it's a logical deletion.

The payload (delete_envelope.json) on the example above, follows the schema below:

```
{
  "envelope_community":"ce_registry",
  "envelope_id":"1ebc0d10-4528-42f4-8ce1-c3aab222e6a4",
  "delete_token":"eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJkZWxldGUiOnRydWV9.pwMSRnpgG4NM1m1Gw6yT2LojSdNzQ35xkG0tWbNoQTo2StaWT3qkGYT06KWRX3a_0924kvvq-0_uHryU88qcmDD0X-GkOxjUDLdVVYOwZBWdmw8yKBBhaWjjoP5LS1sOBjHNW1COrj35GZghbPwlA7RGGPpKHDIulQW_6biWxDbznGL6Lay6gul7H8dKMeJHjWGPF390tTKe4_COUK26s4APBdXUxKdAF-4E7xtJFQZJP-gVlUitNYmvuNFNL3wR6NvaXqEQd--o24DE10tEO44cf6jZFR1LY4iXAOznnveM64NaQnNpPtQwlJYAnIPotUWQgmuixI-g_4aPB61VJQ",
  "delete_token_format":"json",
  "delete_token_encoding":"jwt",
  "delete_token_public_key":"-----BEGIN PUBLIC KEY-----\nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAyLYNBXiEcTF9OaSmmJ8r\nlpd1KEdufmvhpt8MlUTWnOEJr0CrWwvR/jMJ5B9CGMcu83Mcb214hcynoAxPrJJS\nL/pLUtY7xhYFILXDcXu/+Rl3I7km3mXzDc7uuD3DK84Ed70QsFkIR9BzX1VGwDQx\nJEKq4GNljXTV0QvAuiQiVFSFzPh4p9lDaUzGGhzDLiTNiS6Icq6bqc/mUNApRWNY\nlF13PDWksGGyUlhgFP3FFOPj2qYi4FDf8ToHYdOziFAYTtkSQjUvRhkz+xDVSR6p\now742ZZs078Ubyin01Qe9qTbZhby6wuXoIBHfch9/QvlGKLVxcd4utii1A8Q/IGl\nTwIDAQAB\n-----END PUBLIC KEY-----\n"
}

```

where:

- envelope_community: 'ce-registry'
- envelope_id: the id of the envelope to be deleted
- delete_token: is **any** json encoded in JWT using your key pair. This is used
                to guarantee that it's you who are sending the request (only
                the bearer of the private key, can provide a valid token).
                For example: you can use the json `{"delete": true}`
- delete_token_format: only 'json' for now
- delete_token_encoding: only 'jwt' for now
- delete_token_public_key: It has to be the **same key** used to send this envelope,
                           i.e: only the creator can delete it. A different key
                           would cause a "Signature verification raised" error

For the responses keep in mind that:

- as always `422` responses indicates validation errors, check the body for the messages.

- `204 No Content` is the success response, indicating that this resource/content is no longer available.


## 10 - Requesting deleted envelopes

Since deleting an envelope is purely logical, meaning that the envelope is only marked as deleted, you can retrieve deleted records using API parameters.

Add these parameters to any API request to include the deleted records into the result set:

- `?include_deleted=true` - returns all records including deleted ones
- `?include_deleted=only` - returns only deleted records

For example:
`GET /api/ce-registry/envelopes?include_deleted=true` - should return a list of envelopes including the deleted ones.

These parameters also work with search requests. [Read more about searching envelopes](/docs/07_search.md).

-----

For more info check our swagger docs and the json-schemas.
In case of any doubt or sugestion on how to improve this guide, please contact us.
You can provide an issue on github.
