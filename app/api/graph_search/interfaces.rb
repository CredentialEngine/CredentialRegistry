EntityInterface = GraphQL::InterfaceType.define do
  name 'Entity'
  description 'Basic entity in the Credential Registry'

  field :type, !types.String, hash_key: :type
  field :id, types.String, hash_key: :id
  field :ctid, types.String, hash_key: :ctid
  field :name, types.String, hash_key: :name
  field :image, types.String, hash_key: :image
end
