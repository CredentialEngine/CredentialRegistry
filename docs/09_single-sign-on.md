## Single Sign-on

You can use an identity and access management system like Keycloak to authenticate API requests.

### Server Configuration

Each access token must include the name of the community it was issued for.

1. Create a new scope for your client (e.g. `credreg_client_scope`).
2. Add a mapper to the scope (e.g. `credreg_client_scope_mapper`).
3. Set the mapper's token claim name (e.g. `credreg_community_name`).
4. Populate the mapper's claim value with the name of the community the tokens will be issued for.

### App Configuration

Set the following environment variable pointing at your SSO server:

| Variable                     | Description                                      |
| ---------------------------- | ------------------------------------------------ |
| IAM_CLIENT_ID                | The name of the client                           |
| IAM_COMMUNITY_CLAIM_NAME     | The name of the claim referring to the community |
| IAM_COMMUNITY_ROLE_ADMIN     | The administrator role                           |
| IAM_COMMUNITY_ROLE_READER    | The reader role                                  |
| IAM_COMMUNITY_ROLE_PUBLISHER | The publisher role                               |
| IAM_URL                      | The address of the server including the realm    |

Example:

```
IAM_CLIENT_ID=credreg_client
IAM_COMMUNITY_CLAIM_NAME=credreg_community_name
IAM_COMMUNITY_ROLE_ADMIN=ADMIN
IAM_COMMUNITY_ROLE_READER=READER
IAM_COMMUNITY_ROLE_PUBLISHER=PUBLISHER
IAM_URL=https://example.org/realms/credreg_realm
```

### Access Token

Obtain an access token from the SSO server:

```bash
curl --request POST \
  --url <IAM_URL>/protocol/openid-connect/token \
  --data grant_type=client_credentials \
  --data client_id=<IAM_CLIENT_ID> \
  --data client_secret=<your client secret>
```

The decoded token should look like this:

```json
{
  …
  "iss": "https://example.org/realms/credreg_realm",
  "aud": [
    "credreg_client"
  ],
  "typ": "Bearer",
  "azp": "credreg_service_account",
  "resource_access": {
    "credreg_client": {
      "roles": [
        "ADMIN"
      ]
    }
  },
  "scope": "email credreg_client_scope profile",
  "credreg_community_name": "credential-registry"
  …
}
```

### Usage

Authenticate API requests by providing the token in the Authorization header:

```
Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCIgOiA…
```
