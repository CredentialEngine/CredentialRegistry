require_relative '../../config/environment'
require_relative '../../lib/graph_search_helper'
require_relative '../models/query_condition'

# Performs Neo4j searches on several entities by traversing the relations that link them
class GraphSearch
  include GraphSearchHelper

  attr_reader :conditions, :roles

  def initialize(conditions = [], roles = [])
    @query = Neo4j::Session.query
    @conditions = parse_conditions(conditions)
    @roles = convert_roles(roles)
  end

  def organizations
    entity = 'organization'
    paths = %w[credential assessment_profile learning_opportunity_profile].map do |target|
      "(organization)-[#{roles}]-(#{target})"
    end
    @query = base_match_for_organizations
    @query = join_paths(paths).where(credential_clause).where(organization_clause)
    perform_filtering(entity, %w[credential assessment_profile learning_opportunity_profile])
    @query.limit(100).pluck("distinct #{entity}")
  end

  def credentials(start_from = 'credential')
    paths = credential_paths.map { |path| "(organization)-[#{roles}]-#{path}" }
    @query = base_match_for_credentials
    @query = join_paths(paths).where(credential_clause).where(organization_clause)
    perform_filtering(start_from, %w[assessment_profile learning_opportunity_profile])
    @query.limit(100).pluck("distinct #{start_from}")
  end

  def competencies
    credentials('competency')
  end

  %w[assessment_profiles learning_opportunity_profiles].each do |method|
    define_method(method) do
      entity = Dry::Inflector.new.singularize(method)
      @query = @query.match("(#{entity}:#{extract_label(entity)})-[#{roles}]-(organization)")
                     .where(organization_clause)
      perform_filtering(entity)
      @query.limit(100).pluck("distinct #{entity}")
    end
  end

  private

  def base_match_for_organizations
    @query.match(:organization,
                 :credential,
                 assessment_profile: 'AssessmentProfile',
                 learning_opportunity_profile: 'LearningOpportunityProfile')
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

  def credential_paths
    ['(credential)-[:requires]-(condition_profile)-[:targetCompetency]-'\
     '(credential_alignment_object)-[:targetNode]-(competency)',
     '(credential)-[:requires]-(condition_profile)-[:targetAssessment]-(assessment_profile)-'\
     '[:assesses|:requires]-(credential_alignment_object)-[:targetNode]-(competency)',
     '(credential)-[:requires]-(condition_profile)-[:targetLearningOpportunity]-'\
     '(learning_opportunity_profile)-[:teaches|:requires]-(credential_alignment_object)-'\
     '[:targetNode]-(competency)',
     '(credential)-[:requires]-(condition_profile)-[:targetCredential]-(credential)-[:requires]-'\
     '(condition_profile)-[:targetCompetency]-(credential_alignment_object)-[:targetNode]-'\
     '(competency)']
  end

  def base_match_for_credentials
    @query.match(assessment_profile: 'AssessmentProfile').break
          .with(:assessment_profile)
          .match(learning_opportunity_profile: 'LearningOpportunityProfile').break
          .with(:assessment_profile, :learning_opportunity_profile)
          .match('(organization)--(credential)--(condition_profile:ConditionProfile)-[*1..2]-'\
                 '(credential_alignment_object:CredentialAlignmentObject)--(competency:Competency)')
  end

  def join_paths(paths)
    @query.where("(#{paths.join(' OR ')})")
  end

  def perform_filtering(entity, specific_variables = [])
    conditions.each do |condition|
      element = File.basename(condition.element)
      variable = extract_variable(condition.object.value || entity)
      if specific_variables.include?(variable)
        @query = @query.match("(#{entity})-[*1..2]-(#{variable})")
      end
      composite_variable = build_composite_match(condition, variable)
      @query = where_clause(@query, element, condition.value, composite_variable)
    end
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
      @query = @query.break.match("(#{variable})-#{composite_clause}-(#{composite_variable})")
      composite_variable
    else
      variable
    end
  end
end
