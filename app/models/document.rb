# Stores an original document as received from the user and after being
# processed by the node
class Document < ActiveRecord::Base
  enum doc_type: { resource_data: 0 }
  enum user_envelope_format: { json: 0, xml: 1 }
  enum node_headers_format: { jwt: 0 }

  before_validation :generate_doc_id, on: :create

  validates :doc_type, :doc_version, :doc_id, :user_envelope,
            :user_envelope_format, presence: true
  validates :doc_id, uniqueness: true

  scope :ordered_by_date, -> { order(:created_at) }

  def generate_doc_id
    self.doc_id = SecureRandom.uuid unless attribute_present?(:doc_id)
  end
end
