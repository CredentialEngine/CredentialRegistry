require_relative '../../../app/services/graph_search'

QueryConditionType = GraphQL::InputObjectType.define do
  name 'QueryCondition'
  description 'A custom data structure to hold filtering conditions'
  argument :object, types.String
  argument :element, !types.String
  argument :value, !types.String
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
  name 'Organization'
  description 'Credential Engine organizations (both standard and QA)'
  field :type, !types.String, hash_key: :type
  field :id, types.String, hash_key: :id
  field :ctid, types.String, hash_key: :ctid
  field :name, types.String, hash_key: :name
  field :image, types.String, hash_key: :image
  field :socialMedia, types[types.String], hash_key: :socialMedia
  field :address, types[types.String], hash_key: :address
  field :agentType, types[types.String], hash_key: :agentType
end

CredentialType = GraphQL::ObjectType.define do
  name 'Credential'
  description 'Represents any type of credential'
  field :type, !types.String, hash_key: :type
  field :id, types.String, hash_key: :id
  field :ctid, types.String, hash_key: :ctid
  field :name, types.String, hash_key: :name
  field :image, types.String, hash_key: :image
  field :socialMedia, types[types.String], hash_key: :socialMedia
  field :address, types[types.String], hash_key: :address
  field :agentType, types[types.String], hash_key: :agentType
  field :naics, types[types.String], hash_key: :naics
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

  field :organizations do
    description 'Search for organizations'
    type !types[OrganizationType]
    argument :conditions, types[QueryConditionType], default_value: []
    argument :roles, types[AgentRoleEnum], default_value: []
    resolve(lambda do |_obj, args, _ctx|
      GraphSearch.new.organizations(args[:conditions], args[:roles])
    end)
  end

  field :credentials do
    description 'Search for credentials'
    type !types[CredentialType]
    argument :conditions, types[QueryConditionType], default_value: []
    argument :roles, types[AgentRoleEnum], default_value: []
    resolve(lambda do |_obj, args, _ctx|
      GraphSearch.new.credentials(args[:conditions], args[:roles])
    end)
  end
end

Schema = GraphQL::Schema.define do
  query QueryType
end
