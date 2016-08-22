## Search API

Search and filtering are provided on `/api/search`.

You can also use community specific endpoints, i.e: `/api/{community-name}/search`

For communities, like `credential-registry` which has specific resource types,
you can also use endpoints like `/api/{community-name}/{type}/search`.

The search params are described bellow:

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

ex: `GET /api/credential-registry/search`

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
GET /api/search?from=2016-07-20T00:00:00&until=2016-07-31T23:59:59
```

the date params follow the ISO 8601 format.

#### Configuring the search

On the `schemas` folder we split each community/type into its own subfolder,
 each of these can have a `schema.json.erb` and `search.json`.

The schema file as expected contains the json-schema for the community/type,
and the `search.json` is the search config file.

The `fts` key defines which fields will be searchable through full-text-search.
The `properties` will define specific mappings for the resource properties.

```
{
  "description": "Search config for MyCommunity/SubType",

  "fts": [
    {"prop": "schema:name", "weight": 5},
    {"prop": "schema:description", "weight": 1},
    {"prop": "prefix:anotherField", "weight": 2}
  ],
  "properties": {
  }
}
```

For the `fts`, the `prop` determines which properties will be searchable,
and the `weight` says how relevant this field should be.

#### Resource specific types

The `resource_type`, refers to the resource.
They are specific by community, for example: the community `credential-registry`
has the resource_types `Organization` and `Credential`,
whilst the learning registry has no specific type.

- using the `resource_type` query param:

```
GET /api/credential-registry/search?resource_type=credential
GET /api/credential-registry/search?resource_type=organization
```

- using url param:

```
GET /api/credential-registry/credentials/search
GET /api/credential-registry/organizations/search
```
