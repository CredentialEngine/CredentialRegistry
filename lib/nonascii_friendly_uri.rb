# https://stackoverflow.com/a/37599235/341470
module URI
  DOUBLE_ESCAPED_REGEX = /%25([0-9a-f]{2})/i

  class << self
    alias_method :parse_without_escape, :parse

    def parse(uri)
      escaped_uri = DEFAULT_PARSER.escape(uri)
      parse_without_escape(escaped_uri.gsub(DOUBLE_ESCAPED_REGEX, '%\1'))
    end
  end
end
