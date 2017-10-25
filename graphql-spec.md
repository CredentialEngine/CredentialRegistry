# GraphQL specification for Credential Registry

_This is a work in progress_

The purpose of this document is to describe the GraphQL schema and associated types for the search 
interface in the Credential Registry application. The aim is to offer a simpler, more flexible search 
that allows more expressive input queries and results.

First of all, we need to define the entry point for all GraphQL queries. As you can see, we allow 
searching for credentials, assessments, learning opportunities and organizations (both QA as well as
regular ones).

```graphql
type Query {
  credentials: [Credential]!
  assessments: [Assessment]!
  learningOpportunities: [LearningOpportunity]!
  organizations: [CredentialOrganization]!
  qaOrganizations: [QACredentialOrganization]!
}
```

## Credentials, Assessments and Learning Opportunities

### Interfaces

In order to better describe the type hierarchy between the Credential Engine entities, we introduce
the following interfaces:

```graphql
# Common attributes to all entities. The ones displayed here are just a small sample.
interface Entity {
  ctid: ID!
  name: String!
  description: String
  image: String
  keyword: [String]
}
```

```graphql
# More specialized interface for credentials, assessment profiles and learning opportunity profiles.
interface Target {
  subject: String!
  versionIdentifier: String!
  # This allows searching for organizations related to this target. It accepts
  # two arguments: a flag to decide whether to search for QA organizations or not, and an optional 
  # list of agent roles that organizations should match.
  organizations(qa: Boolean = false, role: [AgentRole]): [CredentialOrganization]!
  # The next three entries contain the targets. You can obtain the associated
  # credential, assessment and learning opportunity, based on the specific "ceterms:target*"
  # property
  credential: Credential
  assessment: Assessment
  learningOpportunity: LearningOpportunity
  # The associated contition profiles can be obtained and, optionally, filtered by a list of roles.
  conditions(role: [ConnectionRole]): [Condition]!
}

enum AgentRole {
  OWNED
  OFFERED
  ACCREDITED
  RECOGNIZED
  REGULATED
  RENEWED
  REVOKED
}

enum ConnectionRole {
  REQUIRES
  RECOMMENDS
  PREPARATION_FROM
  ADVANCED_STANDING_FROM
  IS_REQUIRED_FOR
  IS_RECOMMENDED_FOR
  IS_PREPARATION_FOR
  IS_ADVANCED_STANDING_FOR
  ENTRY_CONDITION
  COREQUISITE
  RENEWAL
}

```

### Types

The actual schema types are simply manifestations of the above interfaces. Later, they will probably
evolve to contain more specific attributes.

```graphql
type Credential implements Entity, Target { }

type Assessment implements Entity, Target { }

type LearningOpportunity implements Entity, Target { }
```

## Organizations

Here we try to describe the inverse part of the relationship, the one that involves organizations.

### Interfaces

Since the QA organizations are very similar to the regular credential organizations, we decide to 
use an interface called `Agent` to specify their common attributes.

```graphql
# Represents an organization or person
interface Agent {
  # This models the inverse relationship between credential|assesment|learning opportunity
  # and organization. Though the agent roles have different naming, their meaning
  # is the same, so we can just reuse them.
  credentials(role: [AgentRole]): [Credential]!
  assessments(role: [AgentRole]): [Assessment]!
  learningOpportunities(role: [AgentRole]): [LearningOpportunity]!
}
```

### Types

As in the case of the credentials, assessments and learning opportunities, the actual types for the 
organizations are just instantiations of the above interface.

```graphql
type CredentialOrganization implements Entity, Agent { }

type QACredentialOrganization implements Entity, Agent { }
```

The Condition Profile type includes both (optional) references to the additional & alternative 
condition profiles.

```graphql
type Condition implements Entity {
  additonalCondition: Condition
  alternativeCondition: Condition
}
```

## Pagination

Since it's safe to assume the volume of returned results will be quite large, some form of pagination
is going to be needed. We suggest implementing a cursor-style pagination, using an opaque cursor 
encoded in Base64 that, when decoded in the back-end, represents some envelope metadata that allows 
us to fetch the next set of items; for example the creation date. This is actually the approach 
recommended by GraphQL and other big players in the community.

Let's see a small example that shows how this cursor-based pagination could be achieved:

```graphql
{
  credentials(first: 3, after: "MjAxNy0wMS0wMQ==") {
    totalCount
    edges {
      cursor
      node {
         ctid
         name
      }
    }
    pageInfo {
      startCursor
      endCursor
      hasNextPage
    }
  }
}
```

This query asks for the next 3 credentials after a given one specified by a Base64-encoded cursor.

The GraphQL service would return a JSON response similar to this:

```json
{
  "data": {
    "credentials": {
      "totalCount": 52,
      "edges": [
        {
          "node": {
            "ctid": "ce-58F69814-0FDA-49DF-9594-B6A146015874",
            "name": "Construction Health and Safety Technician (CHST)"
          },
          "cursor": "MjAxNy0wMS0wMg=="
        },
        {
          "node": {
            "ctid": "ce-75807024-B162-498F-8CC8-B43781439755",
            "name": "Bachelors of Science in Security Management"
          },
          "cursor": "MjAxNy0wMS0wNQ=="
        },
        {
          "node": {
            "ctid": "ce-F57261C8-B14D-4606-BA2F-4F68AF85354E",
            "name": "Certificate of Completion in Insurance Studies"
          },
          "cursor": "MjAxNy0wMS0yMA=="
        }
      ],
      "pageInfo": {
        "startCursor": "MjAxNy0wMS0wMg==",
        "endCursor": "MjAxNy0wMS0yMA==",
        "hasNextPage": true
      }
    }
  }
}
```

* **`totalCount`** identifies the total number of records the query has produced.
* **`edges`** is a new structure that references the actual data we want to retrieve (credentials in
the example). You can see that **`node`** contains the credential attributes we asked in the query, 
and **`cursor`** contains the cursor for that specific record. This allows us to start the next 
pagination from anywhere we like.
* **`pageInfo`** contains additional information about the pagination, like the first and last 
cursor of the current set, as well as a boolean flag to indicate whether or not we're deadling with 
the last page. The `pageInfo` object can be customized at will.

## Example Queries

Bellow you'll find a few example queries to demonstrate how the client would query the GraphQL 
spec and obtain the desired results.

_Note: these example queries are not exhaustive, and are slightly simplified on purpose for the sake 
of clarity._

**Get credentials whose QA organizations have agent roles 'offeredBy' and 'renewedBy':**

```graphql
{
  credentials {
    ctid
    name
    organizations(qa: true, role: [OFFERED, RENEWED]) {
      ctid
      name
    }
  }
}
```

**Get target assessment & learning opportunity from credentials, as well as any condition profile 
with role `recommends`:**

```graphql
{
  credentials {
    ctid
    name
    versionIdentifier
    assessment {
      ctid
      name
    }
    LearningOpportunity {
      ctid
      name
    }
    conditions(role: [RECOMMENDS]) {
      ctid
      name
    }
  }
}
```

**Similar to the above but querying assessments and learning opportunities instead of credentials, and 
displaying the alternative condition from the main condition:**

```graphql
{
  assessments {
    ctid
    name
    versionIdentifier
    assessment {
      ctid
      name
    }
    LearningOpportunity {
      ctid
      name
    }
    conditions(role: [ENTRY_CONDITION]) {
      alternativeCondition {
        ctid
        name
      }
    }
  }
}

{
  learningOpportunities {
    ctid
    name
    versionIdentifier
    credential {
      ctid
      name
    }
    LearningOpportunity {
      ctid
      name
    }
    conditions(role: [IS_REQUIRED_FOR]) {
      alternativeCondition {
        ctid
        name
      }
    }
  }
}
```

**Search for organizations and their related credentials with agent role == `owns`:**

```graphql
{
  organizations {
    ctid
    name
    credentials(role: [OWNED]) {
      ctid
      name
    }
  }
}
```

**Same for assessments and learning opportunities with agent role equal to `accredits` or `regulates`, 
but in this case want to return QA credential organizations:**

```graphql
{
  qaOrganizations {
    assessments(role: [ACCREDITED, REGULATED]) {
      ctid
      name
    }
    learningOpportunities(role: [ACCREDITED, REGULATED]) {
      ctid
      name
    }
  }
}
```
