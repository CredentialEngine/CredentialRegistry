# Stores an envelope transaction that references the original envelope entity
class EnvelopeTransaction < ActiveRecord::Base
  belongs_to :envelope

  enum status: { created: 0, updated: 1, deleted: 2 }

  validates :status, presence: true

  scope :in_date, (lambda do |date|
    where('date(created_at) = ?', date.to_date).order(:created_at)
  end)
  scope :in_community, (lambda do |community_name|
    where(envelope: Envelope.in_community(community_name))
  end)

  #
  # Dumps a transaction in Base64 format
  #
  def dump
    raise(LR::TransactionNotPersistedError, 'Can not dump a transaction until '\
         'it has been persisted') if new_record?

    transaction = { status: status, date: created_at, envelope: dump_envelope }

    Base64.urlsafe_encode64(transaction.to_json)
  end

  #
  # Builds a new envelope transaction object form the given Base 64
  # representation
  #
  def build_from_dumped_representation(base64_transaction)
    transaction = JSON.parse(Base64.urlsafe_decode64(base64_transaction.strip))

    self.status = transaction['status']
    self.created_at = transaction['date']
    build_envelope(transaction['envelope'])
  end

  private

  def dump_envelope
    envelope_attrs = envelope.version_at(created_at).attributes.symbolize_keys
    envelope_attrs[:envelope_community] = envelope.envelope_community.name

    envelope_attrs.except(:id, :envelope_community_id)
  end

  def build_envelope(attrs)
    community_name = attrs.delete('envelope_community')
    community = EnvelopeCommunity.find_or_create_by!(name: community_name)

    self.envelope = Envelope.find_or_initialize_by(
      envelope_id: attrs['envelope_id']
    )
    envelope.assign_attributes(attrs.merge(envelope_community: community))
  end
end
