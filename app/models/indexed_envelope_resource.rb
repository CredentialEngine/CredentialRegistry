require 'indexed_envelope_resource_reference'

# A flattened out version of an envelope resource's payload
class IndexedEnvelopeResource < ActiveRecord::Base
  belongs_to :envelope_community
  belongs_to :envelope_resource
  has_one :envelope, through: :envelope_resource
  has_many :references,
           class_name: 'IndexedEnvelopeResourceReference',
           foreign_key: :resource_id

  before_save :assign_metadata_attributes

  def assign_metadata_attributes
    self.envelope_community = envelope.envelope_community
    self.public_record = !envelope_community.secured?

    self['search:recordCreated'] = envelope.created_at
    self['search:recordOwnedBy'] = envelope.organization&._ctid
    self['search:recordPublishedBy'] = envelope.publishing_organization&._ctid
    self['search:resourcePublishType'] = envelope.resource_publish_type
    self['search:recordUpdated'] = envelope.updated_at
  end
end
