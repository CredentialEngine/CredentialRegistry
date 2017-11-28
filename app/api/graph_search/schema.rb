require_relative 'types'

Schema = GraphQL::Schema.define do
  resolve_type ->(_type, _obj, _ctx) {}
  query QueryType
end
