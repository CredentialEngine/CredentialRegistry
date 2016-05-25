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

    {
      envelope_id: envelope.envelope_id,
      status: status,
      date: created_at,
      envelope: PaperTrail::Serializers::JSON.dump(
        envelope.version_at(created_at)
      )
    }
  end
end
