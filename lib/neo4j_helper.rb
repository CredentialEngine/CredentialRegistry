# Utility methods for Neo4j document importing
module Neo4jHelper
  def node_by_id(id)
    Neo4j::Session.query.match(:n).where(n: { id: id }).pluck(:n).last
  end

  def normalize(str)
    return str unless str.is_a?(String)

    sanitized_str = str
    sanitized_str = str.tr('@', '') if str.start_with?('@')
    sanitized_str = str.split(':').last if str.start_with?('ceterms', 'ceasn')
    sanitized_str
  end

  def cleanup(properties)
    {}.tap do |clean_props|
      properties.except('@context').each do |key, value|
        clean_props[normalize(key).to_sym] = normalize(value)
      end
    end
  end

  def relation_exists?(node, type)
    node.rel(dir: :outgoing, type: type)
  end

  def valid_origin?(uri)
    ENV['VALID_ORIGINS'].split(',').find { |origin| uri.include?(origin) }
  end
end
