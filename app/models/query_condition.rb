require 'dry-struct'

Dry::Types.load_extensions(:maybe)

# Convenience module for dry-types
module Types
  include Dry::Types.module
end

# Placeholder class that represents a query condition in a graph search.
class QueryCondition < Dry::Struct
  constructor_type :schema

  Operators = Types::String.default('EQUAL').enum('EQUAL', 'NOT_EQUAL', 'GREATER_THAN',
                                                  'LESS_THAN', 'CONTAINS', 'STARTS_WITH',
                                                  'ENDS_WITH')
  attribute :object, Types::Strict::String.maybe
  attribute :element, Types::Strict::String
  attribute :operator, Operators
  attribute :value, Types::Any
  attribute :optional, Types::Strict::Bool.default(false)
end
