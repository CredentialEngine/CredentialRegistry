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
  has_many :key_pairs, dependent: :delete_all

  validates :name, presence: true
  validates :admin, presence: true

  normalize_attribute :name, with: :squish

  before_save :ensure_ctid
  after_create :create_key_pair
  before_destroy :remove_deleted_envelopes

  def key_pair
    key_pairs.first
  end

  private

  def create_key_pair
    key_pairs.create!
  end

  def ensure_ctid
    self._ctid ||= SecureRandom.uuid
  end

  def remove_deleted_envelopes
    owned_envelopes.deleted.delete_all
  end
end
