# Administrator Notes

## Default Community

A global default community is configured in the database ([as per `db/seeds.rb`](../blob/master/db/seeds.rb)),
however an instance (host) specific default can be configured via [`config/envelope_communities.json`](../blob/a7e26d4542e0861e1b62fcdcd510819be510e378/config/envelope_communities.json)).

## ID Prefix

If the ID of a resource is the full URL (e.g.
`http://example.com/resources/1234`), the end-user should not have to include
the host and path parts (`http://example.com/resources/`) of the ID. Within
a community, the user should be able to request the resource with the id
(`1234`). The prefix in this example would be `http://example.com/resources/`.

For more information see [Issue #42](https://github.com/CredentialEngine/CredentialRegistry/issues/42).

To configure the prefix, simply state it's value in the community's
configuration file. See [`fixtures/configs/ce_registry.json`](../blob/971e5e2aa1e3778ddcf813bd31c0ff3258bcfc1c/fixtures/configs/ce_registry.json#L78)) as an example.

## Authorized Keys

Generally a registration with the platform is not necessary to interact with it
(i.e. publish, update or retrieval of resources). However if the need arises to
update a JSON Schema for a certain community, only authorized users should be
allowed to do so. Simply place the user's public key in a separate file under
`/config/authorized_keys/:envelope_community`. The user can now update the JSON
schemas with the specified `:envelope_community`.

## Environment Variables

A certain number of environment variables is used to configure the application:

* PostgreSQL database server
   ```
   POSTGRESQL_ADDRESS=localhost
   POSTGRESQL_USERNAME=metadataregistry
   POSTGRESQL_PASSWORD=metadataregistry
   POSTGRESQL_DATABASE=metadataregistry_development
   ```
* Internet Archive (Backups)
   ```
   INTERNET_ARCHIVE_ACCESS_KEY=<YOUR-ACCESS-KEY>
   INTERNET_ARCHIVE_SECRET_KEY=<YOUR-SECRET-KEY>
   ```
* AWS S3 (Backups)
   ```
   AWS_ACCESS_KEY_ID=<YOUR-ACCESS-KEY>
   AWS_SECRET_ACCESS_KEY=<YOUR-SECRET-KEY>
   AWS_REGION=<YOUR AWS REGION>
   ```
