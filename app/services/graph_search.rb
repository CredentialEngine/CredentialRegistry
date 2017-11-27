require_relative '../../config/environment'
require_relative '../../lib/graph_search_helper'
require_relative '../models/query_condition'

# Performs Neo4j searches on several entities by traversing the relations that link them
class GraphSearch
  include GraphSearchHelper

  attr_reader :query_service

  def initialize
    @query_service = Neo4j::Session.query
  end

  def organizations(conditions = [], roles = [])
    query = query_service.match("(organization)-[#{convert_roles(roles)}]-(credential)")
                         .where(credential_clause)
                         .where(organization_clause)
    perform(query, 'organization', conditions)
  end

  private

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

  def perform(query, main_variable, conditions = [])
    @query = query
    parse_conditions(conditions).each { |condition| apply_condition(condition, main_variable) }
    @query.return(main_variable).pluck("distinct #{main_variable}")
  end

  def parse_conditions(conditions)
    parsed_conditions = []
    conditions.each do |condition|
      parsed_conditions << QueryCondition.new(condition.to_h.symbolize_keys)
    end
    parsed_conditions
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
end
