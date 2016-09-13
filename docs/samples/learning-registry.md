# Learning Registry sample

```json
{
  "@context": [
    {
      "@vocab": "http://schema.org/",
      "url": {
        "@type": "@id"
      }
    },
    {
      "lrmi": "http://lrmi.net/the-specification#",
      "educationalAlignment": "lrmi:educationalAlignment",
      "typicalAgeRange": "lrmi:typicalAgeRange",
      "interactivityType": "lrmi:interactivityType",
      "learningResourceType": "lrmi:learningResourceType",
      "useRightsUrl": "lrmi:useRightsUrl"
    }
    {
      "metadataregistry": "http://lr-staging.learningtapestry.com/api/schemas/learning_registry#",
      "registry_metadata": {
        "@id": "metadataregistry:registry_metadata",
        "@type": "@id"
      }
    }
  ],
  "@id": "http://docsteach.org/activities/16/detail",
  "@type": "CreativeWork",
  "name": "The Constitution at Work",
  "thumbnailUrl": "http://docsteach.org/assets/lesson/000/000/022/22_medium.jpg",
  "url": "http://docsteach.org/activities/16/detail",
  "description": "In this activity students will analyze documents that span the course of American history to determine their connection to the U.S. Constitution. Students will then make connections between the documents they have examined and the big ideas found within the Constitution.",
  "typicalAgeRange": "13-18",
  "keywords": "History",
  "dateCreated": "2010-05-20",
  "dateModified": "2015-11-24",
  "language": "en",
  "mediaType": [
    "document",
    "image"
  ],
  "learningResourceType": "learning activity",
  "interactivityType": "active",
  "useRightsUrl": "https://creativecommons.org/publicdomain/zero/1.0/",
  "accessRights": "https://ceds.ed.gov/element/001561#FreeAccess",
  "accessibilityFeature": [
    "alternativeText"
  ],
  "accessibilityHazard": [
    "noFlashingHazard",
    "noMotionSimulationHazard",
    "noSoundHazard"
  ],
  "author": {
    "@type": "Organization",
    "name": "National Archives Education Team",
    "url": "http://www.archives.gov/education/",
    "email": "docsteach@nara.gov"
  },
  "publisher": {
    "@type": "Organization",
    "name": "National Archives and Records Administration",
    "url": "http://www.archives.gov",
    "email": "education@nara.gov"
  },
  "educationalAlignment": [
    {
      "@type": "AlignmentObject",
      "alignmentType": "educationLevel",
      "educationalFramework": "US K-12 Grade Levels",
      "targetName": "8-12"
    },
    {
      "@type": "AlignmentObject",
      "alignmentType": "assesses",
      "educationalFramework": "Common Core State Standards for English Language Arts",
      "targetName": "CCSS.ELA-Literacy.RH.6-8.1",
      "targetUrl": "http://corestandards.org/ELA-Literacy/RH/6-8/1"
    },
    {
      "@type": "AlignmentObject",
      "alignmentType": "teaches",
      "educationalFramework": "Common Core State Standards for English Language Arts",
      "targetName": "CCSS.ELA-Literacy.RH.6-8.1",
      "targetUrl": "http://corestandards.org/ELA-Literacy/RH/6-8/1"
    },
    {
      "@type": "AlignmentObject",
      "alignmentType": "requires",
      "educationalFramework": "Common Core State Standards for English Language Arts",
      "targetName": "CCSS.ELA-Literacy.RH.6-8.1",
      "targetUrl": "http://corestandards.org/ELA-Literacy/RH/6-8/1"
    }
  ],
  "registry_metadata": {
    "digital_signature": {
      "key_location": ["http://goopen.sandbox.learningregistry.net/pubkey"]
    },
    "keys": [
      "EZPublish-1.5",
      "EZPublish"
    ],
    "TOS": {
      "submission_TOS": "http://www.learningregistry.org/tos"
    },
    "payload_placement": "json-ld embedded",
    "identity": {
      "submitter": "joe hobson <joe@navigationnorth.com>",
      "signer": "Alpha Node (Resource Data Signing Key) <administrator@learningregistry.org>",
      "submitter_type": "user"
    },
    "original_envelope": "[string with original LR 1.0 envelope, if available]"
  }
}
```

Properties:

- **@context**: [object] json-ld context (in doubt use the same provided on the sample)

- **@id** : [string] json-ld unique identifier for the resource

- **@type** : [enum] json-ld type. Has to be "CreativeWork" (see http://schema.org)

- **name** : [string] The name of the resource (**required**)

- **url** : [string] URL for the resource (**required**)

- **thumbnailUrl** : [string] A thumbnail image relevant to the resource, must be an URI

- **description** : [string] The description of the resource

- **typicalAgeRange** : [array | string] The typical range of ages for the content’s intended end user. e.g: "7", "7-9", "18-"

- **keywords** : [string] Keywords or tags used to describe this resource. Multiple entries in a keywords list are delimited by commas.

- **dateCreated** : [string] creation date in ISO 8601 date format

- **dateModified** : [string] update date in ISO 8601 date format

- **language** : [string | array[string]] language codes from the IETF BCP 47 standard http://tools.ietf.org/html/bcp47

- **mediaType** : [array[string]] List of media types. Valid entries are: 'document', 'image', 'video', 'podcast', 'audio', 'multimedia'

- **learningResourceType** : [string | array[string]] The predominant type or kind characterizing the learning resource. For example, 'presentation', 'handout'.

- **interactivityType** : [string] The predominant mode of learning supported. Acceptable values are:  'active', 'expositive', or 'mixed'.

- **useRightsUrl** : [string] The URL where the owner specifies permissions for using the resource. For example: 'http://creativecommons.org/licenses/by/3.0/'

- **accessRights** : [string] A URL that identifies the conditions that govern the user’s ability to access a learning resource. For example: 'https://ceds.ed.gov/element/001561#FreeAccess'. See more on: https://ceds.ed.gov/element/001561

- **accessibilityFeature** : [array[string]] Content features of the resource, such as accessible media, alternatives and supported enhancements for accessibility. See more on: https://www.w3.org/wiki/WebSchemas/Accessibility. The valid values are: "alternativeText", "annotations", "audioDescription", "bookmarks", "braille", "captions", "ChemML", "describedMath", "displayTransformability", "highContrastAudio", "highContrastDisplay", "index", "largePrint", "latex", "longDescription", "MathML", "none", "printPageNumbers", "readingOrder", "signLanguage", "structuralNavigation", "tableOfContents", "taggedPDF", "tactileGraphic", "tactileObject", "timingControl", "transcript", "ttsMarkup", "unlocked".

- **accessibilityHazard** : [array[string]] A characteristic of the described resource that is physiologically dangerous to some users. Related to WCAG 2.0 guideline 2.3. See more on: https://www.w3.org/wiki/WebSchemas/Accessibility. The valid values are: "flashing", "noFlashingHazard", "motionSimulation", "noMotionSimulationHazard", "sound", "noSoundHazard".

- **author** : [object] The author of this content. (either a "Person" or a "Organization")
    - **@type** : [string] 'Person' or 'Organization' (see http://schema.org)
    - **name** : [string] The name of the author
    - **url** : [string] The URL for the author
    - **email** : [string] Author's contact e-mail address

- **publisher** : [object] The publisher of the creative work.
    - **@type** : [string] has to be an 'Organization' (see http://schema.org)
    - **name** : [string] The publisher name
    - **url** : [string] Url for the publisher's page
    - **email** : [string] Publisher's contact e-mail address

- **educationalAlignment** : [array[object]] An alignment to an established educational framework.
    - **@type** : [string] must be "AlignmentObject".
    - **alignmentType** : [string] A category of alignment between the learning resource and the framework node. Value must be one of: 'assesses', 'teaches', 'requires', 'textComplexity', 'readingLevel', 'educationalSubject', and 'educationLevel'
    - **educationalFramework** : [string] The framework to which the resource being described is aligned
    - **targetName** : [string] The name of a node in an established educational framework
    - **targetUrl** : [string] The URL of a node in an established educational framework
    - **targetDescription** : [string] The description of a node in an established educational framework

- **registry_metadata** : [object] Specific metadata for this registry. Currently is only used for keeping compatibility with LearningRegistry v1 resources. See more on: http://docs.learningregistry.org/en/latest/spec/Resource_Data_Data_Model/index.html#resource-data-description-data-model
    - **digital_signature** : [object]
        - **key_location** : [array[string]] List of urls for the keys locations
    - **keys** : [array[string]] List of keys
    - **terms_of_service**: [object] Terms of service
        - **submission_tos** [string]
    - **payload_placement** : [string] Must be one of: 'inline',  'linked', 'attached'
    - **identity** : [object]
        - **submitter** : [string]
        - **signer** : [string]
        - **submitter_type** : [string] Must be one of: 'anonymous', 'user', 'agent'
    - **original_envelope** : [string] string with original LR 1.0 envelope, if available
