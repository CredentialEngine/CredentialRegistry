# Paradata

Paradata is a particular kind of metadata that represents how an
'actor' (people, organization, whatever) interacts and perform 'actions' with
a given resource (or 'object').

You can read more about our Paradata definition, for LR v1.0, on:
http://learningregistry.org/wp-content/uploads/2013/06/ParadataTwenty.pdf

For the remaining of this doc, I'll assume you know about paradata and how it
worked on LR, to explore the changes we are making.

## ActivityStreams 2.0

Our new implementation of paradata is based on
[ActivityStreams 2.0](https://www.w3.org/TR/activitystreams-core/).
We used a subset of the exposed properties by the spec, and added a few others.

## Envelope

For the envelope use:

```
"envelope_type": "paradata"
```

this is fundamental so we know how to validate and store this envelope as
'paradata' and not a regular 'resource_data'.


## Schema

Below we provide a small sample of the data format. Notice that paradata should
be encoded as `json-ld`.

```json
{
  "@context": "http://www.w3.org/ns/activitystreams",
  "name": "High school English teachers taught this resource 15 times during the month of May 2011",
  "type": "Taught",
  "actor": {
    "type": "Group",
    "id": "teacher",
    "keywords": [ "high school", "english" ]
  },
  "object": "http://URL/to/lesson",
  "measure": {
    "measureType": "count",
    "value": 15
  },
  "date": "2011-05-01/2011-05-31"
}
```

where:

- **@context** : At least one of the contexts provided should be "http://www.w3.org/ns/activitystreams"
- **name** : Is a high level human-readable string that describes the activity.
- **type** : Is the type of the activity. You can provide anything you want, but if possible use one of the Activity subclasses defined on https://www.w3.org/TR/activitystreams-vocabulary/#activity-types
- **actor** : Refers to the person or group who does something. Can be either a string or a json object.
    - **type** if possible should be one of https://www.w3.org/TR/activitystreams-vocabulary/#actor-types.
    - **keywords** is an extended property we added. Is a list of attributes that describe the actor.
- **object** : Refers to the thing being acted upon. Can be either a string or a json object.
- **measure** : extended property used for measurement/aggregation info.
    - **measureType** : type of the measure being displayed
    - **value** : value or magnitude of the measurement
- **date** : extended field used either for the date of activity ("point in time"), or range for the aggregation/events. If it's a period of time, it contains two dates separated by a slash. This field is defined by RFC3339 and ISO8601.

We still can have:

- **target** : Provides a way of describing where the activity took place, i.e., the indirect object or target, of the activity. Examples:
    - "John added a bookmark to delicio.us", the target is "delicio.us"
    - "Lucy added a blog post", the target is the blog url.
- **related** : Is a collection of things that relate to the paradata (usually the object). It's an array of JSON 'objects'. For example: "The document N is composed of X, Y and Z", the related is a list of "X", "Y" and "Z".


You can check the full json-schema [here](https://github.com/learningtapestry/metadataregistry/blob/master/app/schemas/paradata.json.erb)


## Translating from Paradata 1.0


| paradata 1.0      | Current (ActivityStreams 2.0) |
| ----------------- | ----------------------------  |
| actor             | actor                         |
| actor/objectType  | actor/id                      |
| actor/description | actor/keywords                |
| verb              | type                          |
| verb/measure      | measure                       |
| verb/date         | date                          |
| verb/context      | target                        |
| object            | object                        |
| related           | related                       |
| content           | name                          |
