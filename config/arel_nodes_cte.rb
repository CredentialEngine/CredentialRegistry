# Monkey-patched to generate materialized CTEs by default:
# https://github.com/rails/rails/blob/v7.1.2/activerecord/lib/arel/nodes/cte.rb
module Arel
  module Nodes
    class Cte < Arel::Nodes::Binary
      alias :name :left
      alias :relation :right
      attr_reader :materialized

      def initialize(name, relation, materialized: nil)
        super(name, relation)
        @materialized = true
      end

      def hash
        [name, relation, materialized].hash
      end

      def eql?(other)
        self.class == other.class &&
          self.name == other.name &&
          self.relation == other.relation &&
          self.materialized == other.materialized
      end
      alias :== :eql?

      def to_cte
        self
      end

      def to_table
        Arel::Table.new(name)
      end
    end
  end
end
