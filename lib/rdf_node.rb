# Monkey-patching this class in order to ensure bnodes are unique
module RDF
  class Node # rubocop:todo Style/Documentation
    def initialize(_ = nil)
      @id = RDF::Util::UUID.generate(format: :compact)
    end
  end
end
