# Organization on whose behalf publishing is done
class Organization < ActiveRecord::Base
  include AttributeNormalizer

  NOT_EMPTY = "Organization has published resources, can't be removed".freeze

  belongs_to :admin
  has_many :organization_publishers
  has_many :owned_envelopes, class_name: 'Envelope'
  has_many :published_envelopes,
           class_name: 'Envelope',
           dependent: :delete_all,
           foreign_key: :publishing_organization_id
  has_many :publishers, through: :organization_publishers

  validates :name, presence: true
  validates :admin, presence: true
  validate :ctid_format, if: :_ctid?

  normalize_attribute :name, with: :squish

  before_save :ensure_ctid

  before_destroy :remove_deleted_envelopes

  private

  def ctid_format
    return if _ctid.starts_with?('ce-') && UUID.validate(_ctid[3.._ctid.size - 1])

    errors.add(:_ctid, :invalid)
  end

  def ensure_ctid
    self._ctid ||= "ce-#{SecureRandom.uuid}"
  end

  def remove_deleted_envelopes
    owned_envelopes.deleted.delete_all
  end
end
