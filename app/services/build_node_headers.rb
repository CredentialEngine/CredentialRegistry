# Builds the node headers that are appended to the envelope when it's saved
class BuildNodeHeaders
  attr_reader :envelope

  def initialize(envelope)
    @envelope = envelope
  end

  def headers
    {
      resource_digest:,
      created_at: envelope.created_at,
      updated_at: envelope.updated_at,
      deleted_at: envelope.deleted_at,
      versions: versions_header
    }
  end

  def resource_digest
    Digest::SHA256.base64digest(envelope.resource) if envelope.resource?
  end

  def versions_header
    envelope.versions.map do |version|
      {
        head: version.next.blank?,
        event: version.event,
        created_at: version.created_at,
        author: version.whodunnit,
        url: version_url(version)
      }
    end
  end

  def version_url(version)
    community = envelope.envelope_community.name.dasherize

    if version.next.blank?
      "/#{community}/envelopes/#{envelope.envelope_id}"
    else
      "/#{community}/envelopes/#{envelope.envelope_id}" \
        "/revisions/#{version.next.id}"
    end
  end
end
