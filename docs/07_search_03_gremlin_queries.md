## Example Gremlin queries

### Return all credentials of a certain type

```groovy
g.V()
.has(label,of('ceterms_BachelorDegree'))
```

### Return all organizations where name contains "[word]"

```groovy
g.V()
.has(label,of('ceterms_CredentialOrganization'))
.filter{ it.get().value("ceterms_name") ==~ /.*College.*/ }
```

### Return all certificates requiring a learning opportunity that teaches a competency whose text contains "[some phrase]"

```groovy
g.V()
.as('a')
.has(label,of('ceterms_Certificate'))
.out('ceterms:requires')
.has(label,of('ceterms_ConditionProfile'))
.out('ceterms:targetCompetency')
.has(label,of('ceterms_CredentialAlignmentObject'))
.filter { it.get().value('ceterms_targetNodeName') ==~ /.*(?i)logistics.*/ }
.select('a')
```

### Return all learning opportunities that are accredited by any organization(s) where the organization has an organization type that contains "ceterms:QualityAssuranceOrganization" and a jurisdiction of "Indiana"

```groovy
g.V()
.as('a')
.has(label,of('ceterms_AssessmentProfile'))
.out()
.has(label,of('ceterms_QACredentialOrganization'))
.out('ceterms:address')
.has(label,of('ceterms_Place'))
.has('ceterms_addressRegion', 'IN')
.select('a')
```

### Return all assessments offered by any organization(s) where the organization has a social media value of "[some URL]"

```groovy
g.V()
.has(label,of('ceterms_CredentialOrganization'))
.has('ceterms_socialMedia')
.filter { it.get().value('ceterms_socialMedia').any { it =~ 'twitter' } }
.out()
.has(label,of('ceterms_AssessmentProfile'))
```
