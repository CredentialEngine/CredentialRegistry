# Stores an envelope transaction that references the original envelope entity
class EnvelopeTransaction < ActiveRecord::Base
  belongs_to :envelope

  enum status: { created: 0, updated: 1, deleted: 2 }

  validates :status, presence: true

  scope :in_date, (lambda do |date|
    where('date(created_at) = ?', date.to_date).order(:created_at)
  end)

  def dump
    raise(LR::TransactionNotPersistedError, 'Can not dump a transaction until '\
         'it has been persisted') if new_record?

    transaction = { status: status, date: created_at, envelope: dump_envelope }

    Base64.urlsafe_encode64(transaction.to_json)
  end

  private

  def dump_envelope
    envelope_attrs = envelope.version_at(created_at).attributes.symbolize_keys
    envelope_attrs[:envelope_community] = envelope.envelope_community.name

    envelope_attrs.except(:id, :envelope_community_id)
  end
end
