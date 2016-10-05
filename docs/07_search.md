## Search API

Search and filtering are provided on `/api/search`.

You can also use community specific endpoints, i.e: `/api/{community-name}/search`

For communities, like `ce-registry` which has specific resource types,
you can also use endpoints like `/api/{community-name}/{type}/search`.

The search params are described below:

### General definition

Usually takes the following format, with some modifiers which will be specified
along this document:

```
GET /api/search?fts=fuzzy_search_term&filter1=term1&filter2=term2`
```

### Empty Search

An empty search will perform a `match_all` query.

### Pagination

You can paginate on the search results by using the `page` and `per_page` params.
On the response headers we provide links for the pagination on the `Link` header.

For example:

```
# http ":9292/api/search?page=2&per_page=20" -h

Content-Length: 227025
Content-Type: application/json
Link: <http://localhost:9292/api/search?page=1&per_page=20>; rel="first", <http://localhost:9292/api/search?page=1&per_page=20>; rel="prev", <http://localhost:9292/api/search?page=12&per_page=20>; rel="last", <http://localhost:9292/api/search?page=3&per_page=20>; rel="next"
Per-Page: 20
Total: 223
```

### Full Text Search

Try to find anything related to the provided search term.
Uses the `fts` param:

```
GET /api/search?fts=something
GET /api/{community}/search?fts=something
GET /api/{community}/{type}/search?fts=something
```

### Filter by community

there is two ways:

- using the general search endpoint:

```
GET /api/search?community=community-name`
```

- using the community search endpoint:

```
GET /api/{community-name}/search
```

ex: `GET /api/ce-registry/search`

### Filter by type

by default we search for any type of data envelope, if you want only
resources or paradata, use `type=resource_data` or `type=paradata`

```
GET /api/search?type=paradata
```

**PS**: notice that `type` is related to the envelope,
i.e: which kind of data this envelope holds.
This is different from the `resource_type` like we are going to see below.

### Filter by date range

use the `from` and `until` filters:

```
GET /api/search?from=2016-07-20T00:00:00Z&until=2016-07-31T23:59:59Z
```

the date params usually follow the ISO 8601 format.

You can also provide a natural-language description for the dates. I.e:

```
GET /api/search?from=3 months ago
GET /api/search?until=now
GET /api/search?from=february 1st&until=last week
```

### Resource specific types

The `resource_type`, refers to the resource.
They are specific by community, for example: the community `ce-registry`
has the resource_types `Organization` and `Credential`,
whilst the learning registry has no specific type.

- using the `resource_type` query param:

```
GET /api/ce-registry/search?resource_type=credential
GET /api/ce-registry/search?resource_type=organization
```

- using url param:

```
GET /api/ce-registry/credentials/search
GET /api/ce-registry/organizations/search
```

### Find by any resource field

You can search by any resource key. For example:

```
GET /api/ce-registry/search?ctdl:ctid=urn:ctid:9c699c33-ceb6-4e76-8009-fbfa2e443762
GET /api/ce-registry/search?ctid=urn:ctid:9c699c33-ceb6-4e76-8009-fbfa2e443762
# You can configure aliases for special keys on the `config.json`, i.e: ctid => ctdl.ctid
```

For root-level properties just follow the pattern: `prop_name=value`

You can also query on nested fields by providing a json piece that should be
**contained** on the resource.

I.e., given the resource below:

```
decoded_resource": {
    "@type": "ctdl:Credential",
    "@context": {
        "dc": "http://purl.org/dc/elements/1.1/",
        "dct": "http://dublincore.org/terms/",
        "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
        "ctdl": "[CTI Namespace Not Determined Yet]",
        "rdfs": "http://www.w3.org/2000/01/rdf-schema#",
        "schema": "http://schema.org/"
    },
    "schema:url": "https://www.servsafe.com/manager/food-safety-training-and-certification",
    "schema:name": "ServSafe Food Protection Manager Certification",
    "ctdl:purpose": [
        "Entry level within an occupation"
    ],
    "schema:description": "The ServSafe® program provides food safety training, exams and educational materials to foodservice managers. Students can earn the ServSafe Food Protection Manager Certification, accredited by the American National Standards Institute (ANSI)-Conference for Food Protection (CFP).",
    "ctdl:credentialType": [
        "Certification"
    ],
    "ctdl:credentialLevel": [
        "Postsecondary (Less than 1 year)",
        "Postsecondary (1-3 years)",
        "Postsecondary (3-6 years)",
        "Postsecondary (6+ years)",
        "High School"
    ],
    "ctdl:industryCategory": [
        {
            "@type": "schema:Enumeration",
            "schema:url": "http://www.credreg.net/naics",
            "schema:name": "NAICS",
            "unknown:items": [
                {
                    "@type": "unknown:EnumerationItem",
                    "schema:url": "https://www.census.gov/cgi-bin/sssd/naics/naicsrch?code=311&search=2012",
                    "schema:name": "Food Manufacturing"
                },
                {
                    "@type": "unknown:EnumerationItem",
                    "schema:url": "https://www.census.gov/cgi-bin/sssd/naics/naicsrch?code=31141&search=2012",
                    "schema:name": "Frozen Food Manufacturing"
                },
                {
                    "@type": "unknown:EnumerationItem",
                    "schema:url": "https://www.census.gov/cgi-bin/sssd/naics/naicsrch?code=72233&search=2012",
                    "schema:name": "Mobile Food Services"
                }
            ]
        }
    ],
    "ctdl:industryCategory_Flat": [
        {
            "@type": "unknown:EnumerationItem",
            "schema:url": "https://www.census.gov/cgi-bin/sssd/naics/naicsrch?code=311&search=2012",
            "schema:name": "Food Manufacturing",
            "unknown:frameworkUrl": "http://www.credreg.net/naics",
            "unknown:frameworkName": "NAICS"
        },
        {
            "@type": "unknown:EnumerationItem",
            "schema:url": "https://www.census.gov/cgi-bin/sssd/naics/naicsrch?code=31141&search=2012",
            "schema:name": "Frozen Food Manufacturing",
            "unknown:frameworkUrl": "http://www.credreg.net/naics",
            "unknown:frameworkName": "NAICS"
        },
        {
            "@type": "unknown:EnumerationItem",
            "schema:url": "https://www.census.gov/cgi-bin/sssd/naics/naicsrch?code=72233&search=2012",
            "schema:name": "Mobile Food Services",
            "unknown:frameworkUrl": "http://www.credreg.net/naics",
            "unknown:frameworkName": "NAICS"
        }
    ]
}

```

You can find entries that has the value "High School" on the array `ctdl:credentialLevel`, using:

```
GET /api/ce-registry/search?ctdl:credentialLevel=["High School"]
```

Now let's suppose you want to search for entries with an 'industryCategory' item with the name 'Food Manufacturing':

```
GET /api/ce-registry/search?ctdl:industryCategory=[{"unknown:items": [{"schema:name": "Food Manufacturing"}]}]
# OR
GET /api/ce-registry/search?ctdl:industryCategory_Flat=[{"schema:name": "Food Manufacturing"}]
```

and so forth, all you need to do is provide a valid piece of json that should be **contained** on the resource.


### Configuring the resources

We have two configuration files:

#### JSON-schema

contains the json-schema. Can have the forms:

- `{schema-name}.json.erb`
- `{community-name}.json.erb`
- `{community-name}/schema.json.erb`
- `{community-name}/{resource-type}.json.erb`
- `{community-name}/{resource-type}/schema.json.erb`

#### Config

The `config.json` file, which should be placed on the community folder.

I.e: `{community-name}/config.json`


For example (`ce_registry/config.json`):

```
{
  "description": "Config for CE/Registry",

  "resource_type": {
    "property": "@type",
    "values_map": {
      "ctdl:Organization": "organization",
      "ctdl:Credential": "credential"
    }
  },

  "aliases": {
    "ctid": "ctdl:ctid"
  },

  "credential": {
    "fts": {
      "full": ["schema:name", "schema:description"],
      "partial": ["schema:name"]
    },
    "properties": {}
  },

  "organization": {
    "fts": {
      "full": ["schema:name", "schema:description", "schema:purpose"],
      "partial": ["schema:name"]
    }
  }
}
```

where:

- **description** : simple text description for this config
- **aliases** : simple aliases mapping for special keys, i.e: `"original_prop_name": "my-alias-for-search"`
- **{resource_type}**: the properties with a resource_type name has **search** specific configs.
    - **fts**: Full-text-search config object
        - **full**: properties to be matched as full words
        - **partial**: properties to be matched as fuzzy partials (avoid this for big fields, for example 'description' and etc.)

- **resource_type**: Can have 2 formats:
    - Simple string: in this case the resource_type will be the direct value of the property specified.

    ```
      "resource_type": "@type"
    ```

    - Object:
      - **property** : has the property name where the type is specified
      - **values_map**: is a simple mapping with the original values as keys (which occurs on the json), and the target value (used on the queries) as values.


    ```
      "property": "@type",
      "values_map": {
        "ctdl:Organization": "organization",
        "ctdl:Credential": "credential"
      }
    ```
