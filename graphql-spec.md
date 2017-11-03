# GraphQL specification for Credential Registry

_This is a work in progress_

The purpose of this document is to describe the GraphQL schema and associated types for the search 
interface in the Credential Registry application. The aim is to offer a simpler, more flexible search 
that allows more expressive input queries and results.

First of all, we need to define the entry point for all GraphQL queries. As you can see, we allow 
searching for credentials, competencies, assessments, learning opportunities and organizations (both 
QA as well as regular ones).

```graphql
type Query {
  credentials(conditions: [QueryCondition], roles: [AgentRole]): [Credential]!
  organizations(conditions: [QueryCondition], roles: [AgentRole]): [Organization]!
  competencies(conditions: [QueryCondition], roles: [AgentRole]): [Competency]!
  assessments(conditions: [QueryCondition], roles: [AgentRole]): [Assessment]!
  learningOpportunities(conditions: [QueryCondition], roles: [AgentRole]): [LearningOpportunity]!
}
```

A query condition is a generic data structure suitable for specifying filtering conditions in our 
queries. 

```graphql
type QueryCondition {
  object: String!
  element: String!
  value: String!
  operator: ConditionOperator! = EQUAL
  optional: Boolean! = false
}
```

```graphql
enum ConditionOperator {
  EQUAL
  NOT_EQUAL
  GREATER_THAN
  LESS_THAN
  CONTAINS
  STARTS_WITH
  ENDS_WITH
}
```

## Credentials, Assessments and Learning Opportunities

### Interfaces

In order to better describe the type hierarchy between the Credential Engine entities, we introduce
the following interfaces:

```graphql
# Common attributes to all entities. The ones displayed here are just a small sample.
interface Entity {
  type: String!
  ctid: ID!
  name: String!
  description: String
  image: String
  keyword: [String]
  # ... 
}
```

```graphql
# More specialized interface for credentials, assessment profiles and learning opportunity profiles.
interface Target {
  subject: String!
  versionIdentifier: String!
  inLanguage: String!
  # This allows searching for organizations related to this target. It accepts
  # two arguments: the organization type and an optional list of agent roles that organizations 
  # should match.
  organizations(type: OrganizationType = STANDARD, roles: [AgentRole]): [Organization]!
  # The associated contition profile (via 'requires' or any other equivalent property)
  condition: Condition
}

enum OrganizationType {
  STANDARD
  QA
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
```

### Types

The actual schema types are simply manifestations of the above interfaces. Later, they will probably
evolve to contain more specific attributes.

```graphql
type Credential implements Entity, Target { }

type Assessment implements Entity, Target { }

type LearningOpportunity implements Entity, Target { }
```

The Condition Profile type includes the `ceterms:target*` references to credential, assessment or 
learning opportunity, as well as both (optional) references to the additional & alternative 
condition profiles.
    
```graphql
type Condition implements Entity {
  credential: Credential
  assessment: Assessment
  learningOpportunity: LearningOpportunity
  additonalCondition: Condition
  alternativeCondition: Condition
}
```

## Organizations

Here we try to describe the inverse part of the relationship, the one that involves organizations.

### Types

We define a single entity for organization that can hold all the different types.

```graphql
type Organization implements Entity {
  type: OrganizationType! = STANDARD
  # This models the inverse relationship between credential|assesment|learning opportunity
  # and organization. Though the agent roles have different naming, their meaning
  # is the same, so we can just reuse them.
  credentials(roles: [AgentRole]): [Credential]!
  assessments(roles: [AgentRole]): [Assessment]!
  learningOpportunities(roles: [AgentRole]): [LearningOpportunity]!
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

Please check the [specific page for examples](graphql-examples.md).
