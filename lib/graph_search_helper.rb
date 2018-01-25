# Utility methods for Neo4j graph searches
module GraphSearchHelper
  def extract_variable(name)
    inflector.underscore(name)
  end

  def extract_label(label)
    inflector.classify(label)
  end

  def random_variable(prefix = 'cond')
    "#{prefix}_#{SecureRandom.hex(5)}"
  end

  def match_clause(object, key)
    { "#{key}": object }
  end

  def where_clause(query, condition, key)
    element = File.basename(condition.element)
    value_container = random_variable('value')
    operator = extract_operator(condition.operator)
    params = { "#{value_container}": condition.value }
    query.where("#{key}.#{element} #{operator} {#{value_container}}").params(params)
  end

  def extract_operator(name)
    operators = { equal: '=',
                  not_equal: '<>',
                  greater_than: '>',
                  less_than: '<',
                  contains: 'CONTAINS',
                  starts_with: 'STARTS WITH',
                  ends_with: 'ENDS WITH' }
    operators[name.downcase.to_sym]
  end

  def parse_conditions(conditions)
    parsed_conditions = []
    conditions.each do |condition|
      parsed_conditions << QueryCondition.new(condition.to_h.symbolize_keys)
    end
    sort_by_complexity(parsed_conditions)
  end

  #
  # Puts simple conditions at the beginning so that they reference the main MATCH
  #
  def sort_by_complexity(conditions)
    conditions.sort_by { |condition| condition.element.split('/').size }
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

  private

  def inflector
    @inflector ||= Dry::Inflector.new
  end
end
