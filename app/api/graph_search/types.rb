require_relative 'interfaces'
require_relative '../../../app/services/graph_search'

ValueType = GraphQL::ScalarType.define do
  name 'Value'
  description 'Custom type that simply passes the value without applying any coercion'
  coerce_input ->(value, _ctx) { value }
  coerce_result ->(value, _ctx) { value }
end

QueryConditionType = GraphQL::InputObjectType.define do
  name 'QueryCondition'
  description 'A custom data structure to hold filtering conditions'
  argument :object, types.String
  argument :element, !types.String
  argument :value, !ValueType
  argument :operator, ConditionOperatorEnum, default_value: 'EQUAL'
  argument :optional, types.Boolean, default_value: false
end

ConditionOperatorEnum = GraphQL::EnumType.define do
  name 'ConditionOperator'
  description 'Different operators to apply in conditions'
  value('EQUAL')
  value('NOT_EQUAL')
  value('GREATER_THAN')
  value('LESS_THAN')
  value('CONTAINS')
  value('STARTS_WITH')
  value('ENDS_WITH')
end

OrganizationType = GraphQL::ObjectType.define do
  interfaces [EntityInterface]
  name 'Organization'
  description 'Credential Engine organizations (both standard and QA)'

  field :duns, types.String, hash_key: :duns
  field :socialMedia, types[types.String], hash_key: :socialMedia
  field :foundingDate, types.String, hash_key: :foundingDate
end

CredentialType = GraphQL::ObjectType.define do
  interfaces [EntityInterface, WorkInterface]
  name 'Credential'
  description 'Represents any type of credential'
end

AssessmentType = GraphQL::ObjectType.define do
  interfaces [EntityInterface, WorkInterface]
  name 'Assessment'
  description 'Represents an AssessmentProfile entity'
end

LearningOpportunityType = GraphQL::ObjectType.define do
  interfaces [EntityInterface, WorkInterface]
  name 'LearningOpportunity'
  description 'Represents an AssessmentProfile entity'
end

CompetencyType = GraphQL::ObjectType.define do
  interfaces [EntityInterface, WorkInterface]
  name 'Competency'
  description 'Represents a Competency entity'

  field :codedNotation, types.String, hash_key: :codedNotation
end

AgentRoleEnum = GraphQL::EnumType.define do
  name 'AgentRole'
  value('OWNED')
  value('OFFERED')
  value('ACCREDITED')
  value('RECOGNIZED')
  value('REGULATED')
  value('RENEWED')
  value('REVOKED')
end

QueryType = GraphQL::ObjectType.define do
  name 'Query'
  description 'The query root'

  %w[organizations credentials assessmentProfiles learningOpportunityProfiles
     competencies].each do |entity|
    inflector = Dry::Inflector.new
    name = inflector.pluralize(entity.gsub('Profiles', ''))

    field name do
      description "Search for #{inflector.humanize(name)}"
      type !types[Object.const_get(inflector.classify(name).concat('Type'))]
      argument :conditions, types[QueryConditionType], default_value: []
      argument :roles, types[AgentRoleEnum], default_value: []
      resolve(lambda do |_obj, args, _ctx|
        GraphSearch.new(args[:conditions], args[:roles]).public_send(inflector.underscore(entity))
      end)
    end
  end
end
