require_relative '../../config/environment'
require_relative '../../lib/neo4j_helper'
require_relative '../models/query_condition'

# Performs Neo4j searches on Credentials, Organizations and Competencies by traversing the relations
# that link them
class GraphSearch
  include Neo4jHelper

  attr_reader :query_service

  def initialize
    @query_service = Neo4j::Session.query
  end

  def organizations(conditions = [], roles = [])
    main_variable = 'organization'
    @query = query_service.match("(#{main_variable})-[#{convert_roles(roles)}]-(credential)")
                          .where(credential_clause)
                          .where(organization_clause)
    parse_conditions(conditions).each { |condition| apply_condition(condition, main_variable) }
    @query.return(main_variable).pluck("distinct #{main_variable}")
  end

  private

  def convert_roles(roles)
    active_roles = roles.empty? ? all_roles.keys : roles
    converted_roles = []
    active_roles.each { |role| converted_roles += all_roles[role.downcase.to_sym] }
    converted_roles.map { |role| ":#{role}" }.join('|')
  end

  def all_roles
    {
      owned: %w[ownedBy owns],
      offered: %w[offeredBy offers],
      accredited: %w[accreditedBy accredits],
      recognized: %w[recognizedBy recognizes],
      regulated: %w[regulatedBy regulates],
      renewed: %w[renewedBy renews],
      revoked: %w[revokedBy revokes]
    }
  end

  def parse_conditions(conditions)
    parsed_conditions = []
    conditions.each do |condition|
      parsed_conditions << QueryCondition.new(condition.to_h.symbolize_keys)
    end
    parsed_conditions
  end

  def organization_clause(variable = 'organization')
    "#{variable}:CredentialOrganization OR #{variable}:QACredentialOrganization"
  end

  def credential_clause(variable = 'credential')
    credential_types.map { |type| "#{variable}:#{type}" }.join(' OR ')
  end

  def credential_types
    %w[ApprenticeshipCertificate AssociateDegree BachelorDegree Badge Certificate Certification
       Degree DigitalBadge Diploma DoctoralDegree GeneralEducationDevelopment JourneymanCertificate
       License MasterCertificate MasterDegree MicroCredential OpenBadge ProfessionalDoctorate
       QualityAssuranceCredential ResearchDoctorate SecondarySchoolDiploma]
  end

  def assessment_clause(variable = 'assessment_profile')
    "#{variable}:AssessmentProfile"
  end

  def learning_opportunity_clause(variable = 'learning_opportunity')
    "#{variable}:LearningOpportunity"
  end

  def apply_condition(condition, main_variable)
    element = File.basename(condition.element)
    variable = extract_variable((condition.object && condition.object.value) || main_variable)
    relation_variable = build_composite_match(condition, variable)
    @query = @query.where(where_clause(element, condition.value, relation_variable))
  end

  #
  # Builds the MATCH clauses for composite conditions (those that reach external nodes,
  # i.e: 'availableAt/postalCode')
  # Returns the newly created variable, in case relations are present, for other components to
  # reference it. Otherwise returns the current condition variable.
  #
  def build_composite_match(condition, variable)
    relations = File.dirname(condition.element).split('/').reject { |r| r == '.' }
    if relations.any?
      relation_variable = random_variable
      relations_clause = relations.map { |relation| "[:#{relation}]" }.join('-()-')
      @query = @query.match("(#{variable})-#{relations_clause}-(#{relation_variable})")
      relation_variable
    else
      variable
    end
  end

  def extract_variable(name)
    Dry::Inflector.new.underscore(name)
  end

  def random_variable
    "cond_#{SecureRandom.hex(5)}"
  end

  def match_clause(object, key)
    clause = {}
    clause[key] = object
    clause
  end

  def where_clause(element, value, key)
    clause = {}
    clause[key] = {}
    clause[key][element] = value
    clause
  end
end
