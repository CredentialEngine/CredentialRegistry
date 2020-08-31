# Converts a blank node ID into a dummy URI
class ConvertBnodeToUri
  def self.call(value)
    return value unless value.is_a?(String) && value.starts_with?('_:')

    "https://credreg.net/bnodes/#{value[2..-1]}"
  end
end
