class EnvelopeMetadata
  attr_reader :envelope

  def self.from_envelope(envelope)
    new(envelope)
  end

  def initialize(envelope)
    @envelope = envelope
  end

  def as_json(*)
    {
      envelope_community: envelope.envelope_community_name,
      envelope_id: envelope.envelope_id,
      envelope_ceterms_ctid: envelope.envelope_ceterms_ctid,
      envelope_ctdl_type: envelope.envelope_ctdl_type,
      envelope_type: envelope.envelope_type,
      envelope_version: envelope.envelope_version,
      publisher_id: envelope.publisher_id,
      secondary_publisher_id: envelope.secondary_publisher_id,
      resource_publish_type: envelope.resource_publish_type,
      node_headers: node_headers,
      owned_by: envelope.organization&._ctid,
      published_by: envelope.publishing_organization&._ctid,
      changed: false,
      updated_at: envelope.updated_at,
      last_verified_on: envelope.last_verified_on
    }
  end

  private

  def node_headers
    headers = envelope.decoded_node_headers

    {
      resource_digest: headers.resource_digest,
      revision_history: Array(headers.versions).map { |version| revision_history_entry(version) },
      created_at: parse_time(headers.created_at),
      updated_at: parse_time(headers.updated_at),
      deleted_at: parse_time(headers.deleted_at)
    }
  end

  def revision_history_entry(version)
    {
      head: version.head,
      event: version.event,
      created_at: parse_time(version.created_at),
      actor: revision_actor(version),
      url: version.url
    }
  end

  def revision_actor(version)
    version.author.presence || version.whodunnit
  end

  def parse_time(value)
    return if value.blank?

    Time.zone.parse(value)
  end
end
