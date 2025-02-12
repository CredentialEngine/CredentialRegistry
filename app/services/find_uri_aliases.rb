require 'json_context'

# Returns aliases of a given URI
class FindUriAliases
  CREDREG_HOST = 'credreg.net'.freeze
  PURL_HOST = 'purl.org'.freeze

  attr_reader :value

  delegate :context, to: JsonContext

  def initialize(value)
    @value = value
    uri = URI.parse(value.gsub(%r{/$}, ''))

    if uri.host.present?
      @full_uri = uri
    else
      @short_uri = value
    end
  rescue URI::InvalidURIError
    nil
  end

  def self.call(value)
    new(value).call
  end

  def call
    [full_uri, redirect_uri, short_uri].compact.map(&:to_s).presence || [value]
  end

  private

  # rubocop:todo Metrics/PerceivedComplexity
  # rubocop:todo Metrics/AbcSize
  def full_uri # rubocop:todo Metrics/CyclomaticComplexity, Metrics/AbcSize, Metrics/PerceivedComplexity
    return @full_uri if namespaces.values.any? { |v| @full_uri.to_s.starts_with?(v) }

    if @full_uri&.host == CREDREG_HOST
      uri = @full_uri.dup
      uri.host = PURL_HOST
      return uri
    end

    return @full_uri if @full_uri

    namespace, value = @short_uri&.split(':')
    URI.parse(context[namespace]) + value if context[namespace]
  rescue URI::InvalidURIError
    nil
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/PerceivedComplexity

  def namespaces
    @namespaces ||= context.select { |_, v| v.is_a?(String) }
  end

  def redirect_uri
    return unless full_uri&.host == PURL_HOST

    uri = full_uri.dup
    uri.host = CREDREG_HOST
    uri
  end

  def short_uri
    return @short_uri if @short_uri

    namespace, uri = namespaces.find { |_, v| full_uri.to_s.starts_with?(v) }
    return unless namespace

    full_uri.to_s.gsub(uri, "#{namespace}:")
  end
end
