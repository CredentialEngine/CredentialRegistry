require_relative '../../config/environment'
require_relative '../../lib/graph_search_helper'
require_relative '../models/query_condition'

# Performs Neo4j searches on several entities by traversing the relations that link them
class GraphSearch
  include GraphSearchHelper

  attr_reader :query_service

  def initialize
    @query_service = Neo4j::Session.query
    @params = { limit_100: 100 }
  end

  def organizations(conditions = [], roles = [])
    active_roles = convert_roles(roles)
    parsed_conditions = parse_conditions(conditions)
    cypher_queries = %w[credential assessment_profile learning_opportunity_profile].map do |target|
      next if inapplicable_conditions?(parsed_conditions, [target, 'organization'])

      path = "(organization)-[#{active_roles}]-(#{target})"
      @query = query_service.match(path).where(send("#{target}_clause")).where(organization_clause)
      perform_filtering('organization', parsed_conditions).to_cypher
    end
    perform_union(cypher_queries, 'organization')
  end

  def credentials(conditions = [], roles = [])
    @query = query_service.match("(credential)-[#{convert_roles(roles)}]-(organization)")
                          .where(credential_clause)
                          .where(organization_clause)
    perform_filtering('credential', parse_conditions(conditions)).pluck('distinct credential')
  end

  %w[assessment_profiles learning_opportunity_profiles].each do |method|
    define_method(method) do |conditions = [], roles = []|
      entity = Dry::Inflector.new.singularize(method)
      @query = query_service.match("(#{entity})-[#{convert_roles(roles)}]-(organization)")
                            .where(send("#{entity}_clause"))
                            .where(organization_clause)
      perform_filtering(entity, parse_conditions(conditions)).pluck("distinct #{entity}")
    end
  end

  private

  #
  # Determines whether some condition in the current query is not applicable (because it references
  # an entity not present in the current path). When that happens the query can not progress
  # further and therefore not executed.
  #
  def inapplicable_conditions?(conditions, accepted_variables)
    conditions.reject do |condition|
      variable = extract_variable(condition.object.value || accepted_variables.last)
      accepted_variables.include?(variable)
    end.any?
  end

  def organization_clause(variable = 'organization')
    "#{variable}:CredentialOrganization OR #{variable}:QACredentialOrganization"
  end

  def credential_clause(variable = 'credential')
    credential_types.map { |type| "#{variable}:#{type}" }.join(' OR ')
  end

  def assessment_profile_clause(variable = 'assessment_profile')
    "#{variable}:AssessmentProfile"
  end

  def learning_opportunity_profile_clause(variable = 'learning_opportunity_profile')
    "#{variable}:LearningOpportunityProfile"
  end

  def credential_types
    %w[ApprenticeshipCertificate AssociateDegree BachelorDegree Badge Certificate Certification
       Degree DigitalBadge Diploma DoctoralDegree GeneralEducationDevelopment JourneymanCertificate
       License MasterCertificate MasterDegree MicroCredential OpenBadge ProfessionalDoctorate
       QualityAssuranceCredential ResearchDoctorate SecondarySchoolDiploma]
  end

  def perform_filtering(main_variable, conditions = [])
    conditions.each { |condition| apply_condition(condition, main_variable) }
    @params.merge!(@query.parameters)
    @query.return("distinct (#{main_variable})").limit(100)
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
    variable = extract_variable(condition.object.value || main_variable)
    composite_variable = build_composite_match(condition, variable)
    @query = where_clause(@query, element, condition.value, composite_variable)
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
      composite_variable = random_variable
      composite_clause = relations.map { |relation| "[:#{relation}]" }.join('-()-')
      @query = @query.match("(#{variable})-#{composite_clause}-(#{composite_variable})")
      composite_variable
    else
      variable
    end
  end

  def perform_union(queries, entity)
    Neo4j::Session.query(queries.compact.join(' UNION '), @params).map { |c| c[entity] }
  end
end
