require_relative '../../app/services/neo4j_import'

describe Neo4jImport, type: :service do
  describe '#initialize' do
    it 'accepts a JSON string as input' do
      json_string = read_file('../../support/fixtures/json/ce_registry/organization/2_valid.json')

      expect(Neo4jImport.new(json_string).json_document.keys).to eq(%w[@type @id])
    end

    it 'accepts an URL as input', :vcr do
      json_url = 'http://lr-staging.learningtapestry.com/resources/ce-6A62B250-A1A2-4D31-A702-CDC2437EFD31'
      json_doc = Neo4jImport.new(json_url).json_document

      expect(json_doc['@type']).to eq('ceterms:CredentialOrganization')
      expect(json_doc['ceterms:ctid']).to eq('ce-6A62B250-A1A2-4D31-A702-CDC2437EFD31')
      expect(json_doc['ceterms:name']).to eq('NOCTI')
    end

    it 'returns an empty object when document can not be fetched', :vcr do
      json_url = 'http://lr-staging.learningtapestry.com/resources/ce-invalid'

      expect(Neo4jImport.new(json_url).json_document).to eq({})
    end
  end

  describe '#create' do
    before(:all) do
      @session = Neo4j::Session
    end

    before(:each) do
      @session.query('MATCH (n) DETACH DELETE n')
    end

    it 'returns an unavailable symbol when json is empty' do
      expect(Neo4jImport.new('{}').create).to eq(:unavailable_document)
    end

    it 'imports the document and its relations', :vcr do
      file = read_file('../../support/fixtures/json/ce_registry/credential/2_valid.json')
      node = Neo4jImport.new(file).create
      main_jurisdiction = dig_relations(node,
                                        :renewal, :estimatedCost, :jurisdiction, :mainJurisdiction)

      expect(node.labels).to eq([:Certification])
      expect(node.props[:id]).to eq('http://lr-staging.learningtapestry.com/resources/ce-28E50037-D306-4F1E-AA9D-22A0E716B7A7')
      expect(node.props[:name]).to eq('Health Informatics')
      expect(node.props[:naics]).to eq(%w[622 62231])
      expect(node.rels.map(&:rel_type).size).to eq(12)
      expect(node.rels.map(&:rel_type).uniq.sort).to eq(%i[renewal subject])
      expect(main_jurisdiction.props[:latitude]).to eq('46.07323')
    end

    it 'traverses and builds all nested nodes', :vcr do
      file = read_file('../../support/fixtures/json/ce_registry/organization/3_valid.json')
      node = Neo4jImport.new(file).create

      related_node = dig_relations(node, :accreditedIn, :assertedBy)
      relations = related_node.rels(dir: :outgoing).map(&:rel_type).sort

      expect(related_node.props[:id]).to eq('http://lr-staging.learningtapestry.com/resources/ce-e9aacbbf-99f7-4f78-9882-00a740a09803')
      expect(related_node.props[:type]).to eq('CredentialOrganization')
      expect(related_node.props[:subjectWebpage]).to eq('http://www.in.gov/pla/3002.htm')
      expect(relations).to eq(%i[agentSectorType agentType])
    end

    it 'does not duplicate the import if it already exists' do
      file = read_file('../../support/fixtures/json/ce_registry/credential/1_valid.json')
      neo4j_import = Neo4jImport.new(file)
      neo4j_import.create

      expect(docs_count('MasterDegree')).to eq(1)
      expect { neo4j_import.create }.to_not change { docs_count('MasterDegree') }
    end
  end

  def read_file(path)
    File.read(File.expand_path(path, __FILE__))
  end

  def docs_count(label)
    @session.query.match(n: label).pluck('COUNT(n)').first
  end

  def dig_relations(main_node, *relations)
    node = main_node
    relations.each { |relation| node = node.rel(type: relation).end_node }
    node
  end
end
