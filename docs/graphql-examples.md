# GraphQL Example Queries

Bellow you'll find a few example queries to demonstrate how the client would query the GraphQL
spec and obtain the desired results.

_Note: these example queries, as well as the displayed outcomes, are not exhaustive, and are
slightly simplified on purpose for the sake of clarity._

**1. Get the ctid and name from credentials where their competencies contain 'robotics' in
their description:**

You can observe that we build an array of query conditions where we set the following fields:

- The `object` that needs to support the query. Can be any class that exists in the search pathway (
`ConditionProfile`, `AlignmentObject`, `Competency`, etc.). When not set, it's assumed to refer to the
object being managed in the current level.
- The `element` contains the element we want to qualify.
- The `value` contains what we want to compare.
- The `operator` indicates the type of operation we want to apply. By default it looks for equality.
- The `optional` flag determines whether the condition can be considered optional (equivalent to
applying it using `OR`), or not (equivalent to applying it using `AND`).

QUERY:

```graphql
{
  credentials(conditions: $conditions) {
      ctid
      name
    }
  }
}
```

VARIABLES:

```json
{
  "conditions": [
    {
      "object": "Competency",
      "element": "description",
      "value": "robotics",
      "operator": "CONTAINS"
    }
  ]
}
```

OUTCOME:

```json
{
  "data": {
    "credentials": [
      {
        "ctid": "ce-58F69814-0FDA-49DF-9594-B6A146015874",
        "name": "Construction Health and Safety Technician (CHST)"
      },
      {
        "ctid": "ce-75807024-B162-498F-8CC8-B43781439755",
        "name": "Bachelors of Science in Security Management"
      }
    ]
  }
}
```

**2. Get the ctid and name from competencies whose credentials are available at 'Montreal':**

In this case we're traversing the relationship in the opposite direction, from credentials to
competencies.

When searching inside sub-elements, you may specify the full path to the field,
in a similar way to a file system or XPath query. This could also be used in the future to search
inside language maps (e.g. `name/en-US`).

QUERY:

```graphql
{
  competencies(conditions: $conditions) {
      ctid
      name
    }
  }
}
```

VARIABLES:

```json
{
  "conditions": [
    {
      "object": "Credential",
      "element": "availableAt/addressLocality",
      "value": "Montreal"
    }
  ]
}
```

OUTCOME:

```json
{
  "data": {
    "competencies": [
      {
        "ctid": "ce-FD6F9B35-40E6-4424-AFC5-DAA942EFB124",
        "name": "Mathematics"
      },
      {
        "ctid": "ce-2E96FD31-7761-4524-B104-20CED12936A5",
        "name": "Physics"
      }
    ]
  }
}
```

**3. Get credentials of type Certification where their condition profile's audience type is different
from 'Citizen' and their assessment prices are greater than 300$:**

This example implies the use of more than one query condition.

QUERY:

```graphql
{
  credentials(conditions: $conditions) {
      ctid
      type
    }
  }
}
```

VARIABLES:

```json
{
  "conditions": [
    {
      "element": "@type",
      "value": "ceterms:Certification"
    },
    {
      "object": "Condition",
      "element": "audienceType/targetNodeName",
      "value": "Citizen"
    },
    {
      "object": "Assessment",
      "element": "estimatedCost/price",
      "value": 300,
      "operator": "GREATER_THAN"
    }
  ]
}
```

OUTCOME:

```json
{
  "data": {
    "credentials": [
      {
        "ctid": "ce-6B68DF02-12C8-4C4B-A45B-5D6F8D96AC57",
        "type": "ceterms:Certification"
      },
      {
        "ctid": "ce-F92BABDF-ECBD-4FA3-982D-FB694D8A8A79",
        "type": "ceterms:Certification"
      }
    ]
  }
}
```

**4. Get credentials offered or renewed by QA organizations whose name contains 'Midwifery Committee':**

QUERY:

```graphql
{
  credentials(roles: $roles, conditions: $conditions) {
    name
    inLanguage
    organizations(roles: ["OWNED"]) {
       name
    }
  }
}
```

Note how, besides querying for all credentials offered or renewed, we're additionally displaying
the name of the organizations linked to every credential with the role `ownedBy`.

VARIABLES:

```json
{
  "conditions": [
    {
      "element": "name",
      "value": "Midwifery Committee",
      "operator": "CONTAINS"
    },
    {
      "object": "Organization",
      "element": "@type",
      "value": "ceterms:QACredentialOrganization"
    }
  ],
  "roles": [
    "OWNED",
    "RENEWED"
  ]
}
```

OUTCOME:

```json
{
  "data": {
    "credentials": [
      {
        "name": "Bachelor of Science in Computer Science",
        "inLanguage": "English",
        "organizations": [
          {
            "name": "Indiana State Psychology Board"
          }
        ]
      },
      {
        "name": "Certified ISO/IEC 27001 Lead Auditor",
        "inLanguage": "English",
        "organizations": [
          {
            "name": "Indiana State Board of Nursing"
          },
          {
            "name": "Indiana Commission for Higher Education"
          }
        ]
      }
    ]
  }
}
```

**5. Get organizations that are government agencies or offer master degrees in english:**

QUERY:

```graphql
{
  organizations(roles: $roles, conditions: $conditions) {
    name
    description
  }
}
```

VARIABLES:

```json
{
  "conditions": [
    {
      "object": "Credential",
      "element": "@type",
      "value": "ceterms:MasterDegree"
    },
    {
      "object": "Credential",
      "element": "inLanguage",
      "value": "English",
      "optional": true
    },
    {
      "element": "agentType/targetNodeName",
      "value": "Government Agency",
      "optional": true
    }
  ],
  "roles": [
    "OWNED"
  ]
}
```

OUTCOME:

```json
{
  "data": {
    "organizations": [
      {
        "name": "Indiana State Board of Nursing",
        "description": "Within the Indiana Professional Licensing Agency"
      },
      {
        "name": "Medical Licensing Board of Indiana",
        "description": "Within the Indiana Professional Licensing Board"
      }
    ]
  }
}
```
