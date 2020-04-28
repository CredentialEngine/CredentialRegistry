# Monkey-patching this class in order to ensure bnodes are unique
class RDF::Node
  def initialize(_ = nil)
    @id = RDF::Util::UUID.generate(format: :compact)
  end
end
