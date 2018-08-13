## Example Gremlin queries

### Return all credentials of a certain type

```groovy
g.V()
.hasLabel('ceterms:BachelorDegree')
```

### Return all organizations where name contains "[word]"

```groovy
g.V()
.hasLabel('ceterms:CredentialOrganization')
.filter{ it.get().value("ceterms:name") ==~ /.*College.*/ }
```

### Return all certificates requiring a learning opportunity that teaches a competency whose text contains "[some phrase]"

```groovy
g.V()
.as('a')
.hasLabel('ceterms:Certificate')
.out('ceterms:requires')
.hasLabel('ceterms:ConditionProfile')
.out('ceterms:targetCompetency')
.hasLabel('ceterms:CredentialAlignmentObject')
.filter { it.get().value('ceterms:targetNodeName') ==~ /.*(?i)logistics.*/ }
.select('a')
```

### Return all learning opportunities that are accredited by any organization(s) where the organization has an organization type that contains "ceterms:QualityAssuranceOrganization" and a jurisdiction of "Indiana"

```groovy
g.V()
.as('a')
.hasLabel('ceterms:AssessmentProfile')
.out()
.hasLabel('ceterms:QACredentialOrganization')
.out('ceterms:address')
.hasLabel('ceterms:Place')
.has('ceterms:addressRegion', 'IN')
.select('a')
```

### Return all assessments offered by any organization(s) where the organization has a social media value of "[some URL]"

```groovy
g.V()
.hasLabel('ceterms:CredentialOrganization')
.has('ceterms:socialMedia')
.filter { it.get().value('ceterms:socialMedia').any { it =~ 'twitter' } }
.out()
.hasLabel('ceterms:AssessmentProfile')
```
