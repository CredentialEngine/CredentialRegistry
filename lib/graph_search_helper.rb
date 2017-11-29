# Utility methods for Neo4j graph searches
module GraphSearchHelper
  def extract_variable(name)
    Dry::Inflector.new.underscore(name)
  end

  def random_variable(prefix = 'cond')
    "#{prefix}_#{SecureRandom.hex(5)}"
  end

  def match_clause(object, key)
    { "#{key}": object }
  end

  def where_clause(query, element, value, key)
    value_container = random_variable('value')
    params = { "#{value_container}": value }
    query.where("#{key}.#{element} = {#{value_container}}").params(params)
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
