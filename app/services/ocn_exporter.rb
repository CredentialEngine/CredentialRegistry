# Converts an envelope to the OCN format
class OCNExporter
  BENEFICIARY_RIGHTS = 'https://credentialengine.org/terms/'.freeze

  CONTAINER_TYPES = {
    'ceasn:CompetencyFramework' => 'Framework',
    'ceterms:Collection' => 'Collection'
  }.freeze

  PROVIDER_META_MODEL = 'https://ocf-collab.org/concepts/f9a2b710-1cc4-4065-85fd-596b3c40906c'.freeze
  REGISTRY_RIGHTS = 'https://www.ocf-collab.org/rights/92be257b-e6b4-4628-9aa9-568787fde431'.freeze

  attr_reader :contextualizing_object_resources, :envelope, :graph

  delegate :envelope_community, to: :envelope

  def initialize(envelope:)
    @contextualizing_object_resources = {
      'Credential' => Set.new,
      'Industry' => Set.new,
      'LearningOpportunity' => Set.new,
      'Occupation' => Set.new
    }

    @envelope = envelope
    @graph = envelope.processed_resource.fetch('@graph')
  end

  def assessment_industry_ids(resource)
    result = EnvelopeResource.connection.execute <<~SQL
      SELECT DISTINCT envelope_resources.processed_resource
      FROM indexed_envelope_resources subject
      INNER JOIN indexed_envelope_resource_references ref1
      ON subject."@id" = ref1.resource_uri
      AND ref1.path = 'ceterms:assesses'
      INNER JOIN indexed_envelope_resource_references ref2
      ON ref1.subresource_uri = ref2.resource_uri
      AND ref2.path = 'ceterms:targetNode'
      INNER JOIN envelope_resources
      ON subject.envelope_resource_id = envelope_resources.id
      WHERE envelope_resources.resource_type = 'assessment_profile'
      AND ref2.subresource_uri = '#{resource.fetch('@id')}'
      AND envelope_resources.processed_resource->'ceterms:industryType' IS NOT NULL
    SQL

    resources = result.to_a.map { JSON(_1.values.first) }
    contextualizing_object_resources['Industry'] += resources
    resources.map { _1.fetch('@id') }
  end

  def cao_ids(property:, resource:, type:)
    caos = resource
      .fetch(property, [])
      .select { _1['ceterms:targetNode'].present? }

    contextualizing_object_resources[type] += caos
    caos.map { _1.fetch('ceterms:targetNode') }
  end

  def category(resource)
    if (identifiers = Array.wrap(resource['ceterms:identifier'])).present?
      identifiers.map do |identifier|
        {
          type: 'CategoryCode',
          codeValue: identifier.fetch('ceterms:identifierValueCode'),
          name: {
            'en-us': read_first_value(identifier, keys: 'ceterms:identifierTypeName')
          },
          description: {
            'en-us': read_first_value(identifier, keys: 'ceterms:identifierTypeName')
          },
          inCodeSet: resource['ceterms:identifierType']
        }
      end
    elsif resource['ceterms:codedNotation'].present?
      [{
        type: 'CategoryCode',
        codeValue: resource['ceterms:codedNotation'],
        name: {
          'en-us': read_first_value(resource, keys: 'ceterms:targetNodeName')
        },
        description: {
          'en-us': read_first_value(resource, keys: 'ceterms:targetNodeDescription')
        },
        inCodeSet: resource['ceterms:framework']
      }]
    else
      []
    end
  end

  def competencies
    @competencies ||= competency_resources.map { competency(_1) }
  end

  def competency(resource)
    {
      id: resource.fetch('@id'),
      type: 'Competency',
      containedIn: [container_id],
      competencyText: {
        'en-us': read_first_value(resource, keys: 'ceasn:competencyText')
      },
      dataURL: resource.fetch('@id'),
      contextualizedBy: contextualizing_object_ids(resource)
    }
  end

  def competency_resources
    @competency_resources ||= graph.select { _1.fetch('@type') == 'ceasn:Competency' }
  end

  def container
    @container ||= {
      id: container_id,
      type: container_type,
      fromDirectory: envelope_community.ocn_directory_id,
      dataURL: container_data_url,
      name: {
        'en-us': read_first_value(container_resource, keys: %w[ceasn:name ceterms:name])
      },
      description: {
        'en-us': read_first_value(container_resource, keys: %w[ceasn:description ceterms:description])
      },
      attributionName: {
        'en-us': read_first_value(provider&.processed_resource, keys: 'ceterms:name') || 'Unknown Organization'
      },
      attributionURL: provider_uri,
      beneficiaryRights: BENEFICIARY_RIGHTS,
      providerMetaModel: PROVIDER_META_MODEL,
      registryRights: REGISTRY_RIGHTS
    }
  end

  def container_data_url
    container_id.gsub('/resources/', '/graph/')
  end

  def container_id
    container_resource.fetch('@id')
  end

  def container_name
    read_language_map_value(container_resource, %w[ceasn:name ceterms:name])
  end

  def container_resource
    @container_resource ||= graph.find do |resource|
      CONTAINER_TYPES.keys.include?(resource.fetch('@type'))
    end
  end

  def container_type
    CONTAINER_TYPES[container_resource.fetch('@type')]
  end

  def contextualizing_object(resource:, type:)
    {
      id: read_first_value(resource, keys: %w[ceterms:targetNode @id]),
      type:,
      name: {
        'en-us': read_first_value(resource, keys: %w[ceterms:targetNodeName ceterms:name])
      },
      description: {
        'en-us': read_first_value(resource, keys: %w[ceterms:targetNodeDescription ceterms:description])
      },
      dataURL: read_first_value(resource, keys: %w[ceterms:targetNode ceterms:subjectWebpage]),
      codedNotation: read_coded_notation(resource),
      category: category(resource)
    }
  end

  def contextualizing_object_ids(resource)
    [
      *credential_ids(resource),
      *industry_ids(resource),
      *learning_opportunity_ids(resource),
      *occupation_ids(resource)
    ]
  end

  def contextualizing_objects
    contextualizing_object_resources.map.each do |type, resources|
      resources.map { contextualizing_object(resource: _1, type:) }
    end.flatten
  end

  def credential_ids(resource)
    uris = Array.wrap(resource['ceasn:substantiatingCredential'])
    return [] if uris.empty?

    creds = find_envelope_resources(uris).map(&:processed_resource)
    contextualizing_object_resources['Credential'] += creds
    creds.map { _1.fetch('@id') }
  end

  def credential_industry_ids(resource)
    result = EnvelopeResource.connection.execute <<~SQL
      SELECT DISTINCT envelope_resources.processed_resource
      FROM indexed_envelope_resources subject
      INNER JOIN indexed_envelope_resource_references ref1
      ON subject."@id" = ref1.resource_uri
      INNER JOIN indexed_envelope_resource_references ref2
      ON ref1.subresource_uri = ref2.resource_uri
      AND ref2.path = 'ceterms:targetCompetency'
      INNER JOIN indexed_envelope_resource_references ref3
      ON ref2.subresource_uri = ref3.resource_uri
      AND ref3.path = 'ceterms:targetNode'
      INNER JOIN envelope_resources
      ON subject.envelope_resource_id = envelope_resources.id
      WHERE envelope_resources.resource_type = 'credential'
      AND ref3.subresource_uri = '#{resource.fetch('@id')}'
      AND envelope_resources.processed_resource->'ceterms:industryType' IS NOT NULL
    SQL

    resources = result.to_a.map { JSON(_1.values.first) }
    contextualizing_object_resources['Industry'] += resources
    resources.map { _1.fetch('@id') }
  end

  def directory
    {
      id: envelope_community.ocn_directory_id,
      type: 'Directory',
      name: envelope_community.name,
      dateCreated: envelope_community.created_at.to_date
    }
  end

  def export
    return unless envelope_community.ocn_export_enabled?
    return unless container_resource
    return unless competency_resources.any?

    upload_to_s3
  end

  def find_envelope_resources(ids)
    ctids = Array.wrap(ids).map { _1.split('/').last }

    EnvelopeResource
      .not_deleted
      .where(envelopes: { envelope_community: })
      .where(resource_id: ctids)
  end

  def industry_ids(resource)
    [
      *cao_ids(property: 'ceterms:industryType', resource:, type: 'Industry'),
      *assessment_industry_ids(resource),
      *credential_industry_ids(resource),
      *learning_opportunity_industry_ids(resource)
    ]
  end

  def json_ld
    {
      directory:,
      container:,
      competencies:,
      contextualizingObjects: contextualizing_objects
    }
  end

  def learning_opportunity_ids(resource)
    result = EnvelopeResource.connection.execute <<~SQL
      SELECT envelope_resources.processed_resource
      FROM indexed_envelope_resources subject
      INNER JOIN indexed_envelope_resource_references ref1
      ON subject."@id" = ref1.subresource_uri
      AND ref1.path = 'ceterms:targetNode'
      INNER JOIN indexed_envelope_resource_references ref2
      ON ref1.resource_uri = ref2.subresource_uri
      AND ref2.path = 'ceterms:teaches'
      INNER JOIN indexed_envelope_resources target
      ON ref2.resource_uri = target."@id"
      INNER JOIN envelope_resources
      ON target.envelope_resource_id = envelope_resources.id
      WHERE subject."@id" = '#{resource.fetch("@id")}'
      AND target."@type" IN ('ceterms:Course', 'ceterms:LearningOpportunityProfile', 'ceterms:LearningProgram')
    SQL

    resources = result.to_a.map { JSON(_1.values.first) }
    contextualizing_object_resources['LearningOpportunity'] += resources
    resources.map { _1.fetch('@id') }
  end

  def learning_opportunity_industry_ids(resource)
    result = EnvelopeResource.connection.execute <<~SQL
      SELECT DISTINCT envelope_resources.processed_resource
      FROM indexed_envelope_resources subject
      INNER JOIN indexed_envelope_resource_references ref1
      ON subject."@id" = ref1.resource_uri
      AND ref1.path = 'ceterms:teaches'
      INNER JOIN indexed_envelope_resource_references ref2
      ON ref1.subresource_uri = ref2.resource_uri
      AND ref2.path = 'ceterms:targetNode'
      INNER JOIN envelope_resources
      ON subject.envelope_resource_id = envelope_resources.id
      WHERE envelope_resources.resource_type = 'learning_opportunity_profile'
      AND ref2.subresource_uri = '#{resource.fetch('@id')}'
      AND envelope_resources.processed_resource->'ceterms:industryType' IS NOT NULL
    SQL

    resources = result.to_a.map { JSON(_1.values.first) }
    contextualizing_object_resources['Industry'] += resources
    resources.map { _1.fetch('@id') }
  end

  def occupation_ids(resource)
    cao_ids(property: 'ceterms:occupationType', resource:, type: 'Occupation')
  end

  def provider
    @provider ||= find_envelope_resources(provider_uri).first
  end

  def provider_uri
    read_first_value(container_resource, keys: %w[ceasn:creator ceasn:publisher ceterms:ownedBy ceterms:offeredBy])&.first
  end

  def upload_to_s3
    Aws::S3::Resource
      .new(region: ENV.fetch('AWS_REGION'))
      .bucket(envelope_community.ocn_s3_bucket)
      .object("#{envelope.envelope_ceterms_ctid}.json")
      .put(body: json_ld.to_json)
  end

  private

  def read_coded_notation(resource)
    resource.dig('ceterms:industryType', 0, 'ceterms:codedNotation') ||
    resource.dig('ceterms:occupationType', 0, 'ceterms:codedNotation') ||
    resource['ceterms:codedNotation']
  end

  def read_first_value(resource, keys:)
    return unless resource.present?

    value = resource[Array.wrap(keys).find { resource[_1] }]
    return value unless value.is_a?(Hash)

    value.values.first
  end
end
