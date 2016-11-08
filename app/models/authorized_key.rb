# Check if public is authorized. Used for json_schema envelopes
class AuthorizedKey
  attr_reader :community_name, :key

  def initialize(community_name, key)
    @community_name = community_name
    @key = key.gsub(/\n$/, '') # remove trailing newline
  end

  def valid?
    authorized_keys.include?(key)
  end

  def authorized_keys
    pattern = self.class.base_path + "/#{community_name}/*"
    Dir[pattern].select { |file| !file.start_with?('.') }
                .map    { |path| File.read(path).gsub(/\n$/, '') }
  end

  def self.base_path
    @base_path ||= File.expand_path('../../../config/authorized_keys', __FILE__)
  end
end
