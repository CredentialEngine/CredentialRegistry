# Represents a delete token, used mostly for validation purposes when deleting
# envelopes
class DeleteToken
  include Virtus.model
  include ActiveModel::Validations

  attribute :token, String
  attribute :format, String
  attribute :encoding, String
  attribute :public_key, String

  alias_attribute :delete_token, :token
  alias_attribute :delete_token_format, :format
  alias_attribute :delete_token_encoding, :encoding
  alias_attribute :delete_token_public_key, :public_key

  validates :token, :format, :encoding, :public_key, presence: true
  validates :format, inclusion: { in: %w[json xml] }
  validates :encoding, inclusion: { in: %w[jwt] }
  validate :signature_matches

  def signature_matches
    RSADecodedToken.new(token, public_key)
  rescue StandardError => e
    errors.add :base, e.message
  end
end
