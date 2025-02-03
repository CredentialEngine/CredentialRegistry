# Adds support for some of missing PG operators to Arel
# https://github.com/DavyJonesLocker/postgres_ext
module Arel
  module Nodes
    class ArrayAccess < Arel::Nodes::Binary
      include Arel::AliasPredication
      include Arel::Expressions
      include Arel::Math
      include Arel::OrderPredications
      include Arel::Predications
    end

    class Overlap < Arel::Nodes::Binary # rubocop:todo Style/Documentation
      def operator
        '&&'
      end
    end
  end

  module Predications # rubocop:todo Style/Documentation
    def contains(other)
      Nodes::Contains.new(self, Nodes.build_quoted(other, self))
    end

    def overlap(other)
      Nodes::Overlap.new(self, Nodes.build_quoted(other, self))
    end
  end

  module Visitors
    class PostgreSQL < Arel::Visitors::ToSql # rubocop:todo Style/Documentation
      # rubocop:todo Naming/MethodParameterName
      # rubocop:todo Naming/MethodName
      def visit_Arel_Nodes_ArrayAccess(o, collector) # rubocop:todo Metrics/AbcSize, Naming/MethodName, Naming/MethodParameterName
        # rubocop:enable Naming/MethodName
        # rubocop:enable Naming/MethodParameterName
        collector << '('
        visit(o.left, collector)
        collector << ')'

        if o.right
          collector << '['

          if o.right.is_a?(Range)
            visit(o.right.first, collector)
            collector << ':'
            visit(o.right.last, collector)
          else
            visit(o.right, collector)
          end

          collector << ']'
        end

        collector
      end

      # rubocop:todo Naming/MethodParameterName
      # rubocop:todo Naming/MethodName
      def visit_Arel_Nodes_Contains(o, collector) # rubocop:todo Metrics/AbcSize, Naming/MethodName, Naming/MethodParameterName
        # rubocop:enable Naming/MethodName
        # rubocop:enable Naming/MethodParameterName
        columns = ActiveRecord::Base
                  .connection
                  .schema_cache
                  .columns_hash(o.left.relation.name)
                  .values

        left_column = columns.find do |col|
          col.name == o.left.name.to_s || col.name == o.left.relation.name.to_s
        end

        if left_column&.type == :hstore || (left_column.respond_to?(:array) && left_column.array)
          infix_value(o, collector, ' @> ')
        else
          infix_value(o, collector, ' >> ')
        end
      end

      # rubocop:todo Naming/MethodParameterName
      def visit_Arel_Nodes_Overlap(o, collector) # rubocop:todo Naming/MethodName, Naming/MethodParameterName
        # rubocop:enable Naming/MethodParameterName
        infix_value(o, collector, ' && ')
      end
    end
  end
end
