EntityInterface = GraphQL::InterfaceType.define do
  name 'Entity'
  description 'Basic entity in the Credential Registry'

  field :type, !types.String, hash_key: :type
  field :id, types.String, hash_key: :id
  field :ctid, types.String, hash_key: :ctid
  field :name, types.String, hash_key: :name
  field :image, types.String, hash_key: :image
  field :keyword, types[types.String], hash_key: :keyword
  field :naics, types[types.String], hash_key: :naics
end

WorkInterface = GraphQL::InterfaceType.define do
  name 'Target'
  description 'Entity that includes fields common to credentials, assessments and learning '\
              'opportunities'

  field :inLanguage, types.String, hash_key: :inLanguage
  field :dateEffective, types.String, hash_key: :dateEffective
  field :hasGroupParticipation, types.Boolean, hash_key: :hasGroupParticipation
end
