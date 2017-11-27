# Utility methods for Neo4j graph searches
module GraphSearchHelper
  def extract_variable(name)
    Dry::Inflector.new.underscore(name)
  end

  def random_variable
    "cond_#{SecureRandom.hex(5)}"
  end

  def match_clause(object, key)
    clause = {}
    clause[key] = object
    clause
  end

  def where_clause(element, value, key)
    clause = {}
    clause[key] = {}
    clause[key][element] = value
    clause
  end

  def convert_roles(roles)
    active_roles = roles.empty? ? all_roles.keys : roles
    converted_roles = []
    active_roles.each { |role| converted_roles += all_roles[role.downcase.to_sym] }
    converted_roles.map { |role| ":#{role}" }.join('|')
  end

  def all_roles
    {
      owned: %w[ownedBy owns],
      offered: %w[offeredBy offers],
      accredited: %w[accreditedBy accredits],
      recognized: %w[recognizedBy recognizes],
      regulated: %w[regulatedBy regulates],
      renewed: %w[renewedBy renews],
      revoked: %w[revokedBy revokes]
    }
  end
end
