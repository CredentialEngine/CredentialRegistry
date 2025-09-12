# Envelope Community Config

The envelope community config is a JSON document with the following structure:

| Property              | Type   | Required |
| --------------------- | ------ | -------- |
| aliases               | Object | No       |
| id_field              | String | Yes      |
| resource_type         | Object | No       |
| subclasses_map        | Object | No       |
| [resource type alias] | Object | No       |

### `aliases`

Defines aliases for resource properties intended for the full-text search API:

```json
{
  "aliases": {
    "ctid": "ceterms:ctid"
  }
}
```

### `id_field`

Indicates which resource property contains its ID:

```json
{
  "id_field": "ceterms:ctid"
}
```

### `resource_type`

Defines aliases for resource types intended for the full-text search API:

| Property   | Type   | Required | Description                                         |
| ---------- | ------ | -------- | --------------------------------------------------- |
| property   | String | Yes      | Indicates which resource property contains its type |
| values_map | Object | Yes      | Defines an alias for each resource type             |

Example:

```json
{
  "resource_type": {
    "property": "@type",
    "values_map": {
      "ceterms:Credential": "credential"
    }
  }
}
```

### `subclasses_map`

Indicates which resource types are subclasses of other resource types.

A subclasses map is an object where each key is resource type and its value is either a subclasses map or an empty object.

A subclasses map's structure is described by this JSON Schema:

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "properties": {
    "subclasses_map": {
      "$ref": "#/$defs/subclasses_map"
    }
  },
  "required": ["subclasses_map"],
  "$defs": {
    "subclasses_map": {
      "type": "object",
      "additionalProperties": {
        "$ref": "#/$defs/subclasses_map"
      }
    }
  }
}
```

Example:

```json
{
  "subclasses_map": {
    "ceterms:Credential": {
      "ceterms:Badge": {
        "ceterms:DigitalBadge": {},
        "ceterms:OpenBadge": {}
      }
    }
  }
}
```

Here `ceterms:Credential` has three subclasses: `ceterms:Badge`, `ceterms:DigitalBadge`, and `ceterms:OpenBadge` (the first one directly and the other two through the first one), while `ceterms:Badge` has two: `ceterms:DigitalBadge` and `ceterms:OpenBadge`.

### `[resource type alias]`

Indicates which properties should be used in the full-text search API for each resource type. Example:

```json
{
  "credential": {
    "fts": {
      "full": [
        "$.ceterms:name",
        "$.ceterms:description",
        "$.ceterms:subjectWebpage"
      ],
      "partial": ["$.ceterms:name"]
    }
  }
}
```

The keys are aliases defined in the `resource_type` section and the properties are [JSONPath](https://en.wikipedia.org/wiki/JSONPath) expressions.

## Upload a Config

To upload a config to the community, perform the following request:

```bash
curl --request POST \
  --url 'https://[instance domain]/metadata/[community name]/config' \
  --header 'Authorization: Bearer [access token]' \
  --data '{
  "description": "Sample config",
  "payload": {
    "aliases": {
      "ctid": "ceterms:ctid"
    },
    "resource_type": {
      "property": "@type",
      "values_map": {
        "ceterms:Credential": "credential"
      }
    },
    "credential": {
      "fts": {
        "full": [
          "$.ceterms:name",
          "$.ceterms:description",
          "$.ceterms:subjectWebpage"
        ],
        "partial": [
          "$.ceterms:name"
        ]
      }
    },
    "subclasses_map": {
      "ceterms:Credential": {
        "ceterms:Badge": {
          "ceterms:DigitalBadge": {},
          "ceterms:OpenBadge": {}
        }
      }
    }
  }
}'
```
