## Schemas

The json-schemas, can be defined on fixture files inside the `fixtures/schemas`
folder.
You can check the existing schemas on `GET /api/schemas/info`

But it's possible to update a schema directly via API.
For this you just use an envelope with an encoded resource (the schema),
then perform a `PUT` request on the corresponding schema.

### Resource

The json-schema resources have the following format:

```
{
  "name": "community/type",  // Check /api/schemas/info for valid schema names
  "schema": {
     // ... The json-schema definition
  }
}
```

For example:

```
{
  "name": "ce_registry/organization",
  "schema": {
    "$schema": "http://json-schema.org/draft-04/schema#",
    "description": "CE/Registry Organization metadata",
    "type": "object",
    "properties": {
      "@type": {
        "enum": ["ceterms:Organization", "ceterms:CredentialOrganization"]
      },
      "ceterms:url": {
        "description": "The URL for the resource."
      },
      "ceterms:name": {
        "description": "The name of the resource being described."
      }
      "required": [ "@type", "ceterms:name" ]
    }
  }
}
```

For encoding this resource and sending the envelope you **have to use an
authorized key**, i.e, you need to send the **public key** before to us, so we add it
to the whitelist.

### Envelope

The envelope for json_schema has the following format:

```
{
  "envelope_type": "json_schema",  // CAUTION to not use resource_data
  "envelope_version": "1.0.0",
  "envelope_community": "ce_registry",
  "resource": "<ENCONDED STRING FOR THE SCHEMA RESOURCE>",
  "resource_format": "json",
  "resource_encoding": "jwt",
  "resource_public_key": "<AUTHORIZED PUBLIC KEY>"
}
```

the `envelope_type` must be `json_schema` for this kind of resource.

After creating the envelope you should perform a **PUT** request on this schema,
i.e.:

```
PUT /api/schemas/{schema-name} < envelope.json

# for the example above:
PUT /api/schemas/ce_registry/organization < envelope.json
```

After updating a schema you can check it on `GET /api/schemas/{schema-name}`,
were usually `schema-name` has the format `community/type`
