# Stores an original document as received from the user and after being
# processed by the node
class Document < ActiveRecord::Base
  enum doc_type: { resource_data: 0 }
  enum user_envelope_format: { jwt: 0 }
  enum node_headers_format: { node_headers_jwt: 0 }

  before_validation :generate_doc_id, on: :create

  validates :doc_type, :doc_version, :doc_id, :user_envelope,
            :user_envelope_format, presence: true
  validates :doc_id, uniqueness: true

  def generate_doc_id
    self.doc_id = SecureRandom.uuid
  end
end
