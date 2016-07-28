## API info

Most of our endpoints have a corresponding 'info' with some extra information
and links to relevant docs and specifications.
For example: the endpoint `/api` has a `/api/info`, `/api/schemas` has a `/api/schemas/info` and so forth.

Below we provide a list of the 'info' endpoints and the expected response they will show

- `/api/info`

```
{
  metadata_communities: [ object with metadata_communities and their urls ],
  postman: 'url to postman docs',
  swagger: 'url to swagger docs',
  readme: 'url for readme',
  docs: 'url for docs folder'
}
```

- `/api/schemas/info`

```
{
  available_schemas: [ list of available schema urls ],
  specification: 'http://json-schema.org/'
}
```

- `/api/<community_name>/info`

```
{
    "backup_item": "credential-registry-test",
    "total_envelopes": 1024
}
```

- `/api/<community_name>/envelopes/info`

```
{

}
```
