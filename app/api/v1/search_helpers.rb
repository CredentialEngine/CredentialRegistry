# Search specific helpers
module SearchHelpers
  extend Grape::API::Helpers

  def search_filters
    filters = {
      community: term_for_community,
      envelope_type: params[:type],
      resource_schema_name: term_for_resource_type
    }.compact
    filters.blank? ? nil : filters
  end

  def term_for_community
    community || params[:community].try(:underscore)
  end

  def term_for_resource_type
    if params[:resource_type].present?
      resource_type = params[:resource_type].downcase.singularize
      [term_for_community, resource_type].compact.join('/')
    end
  end

  def search_terms
    terms = {
      fts: params[:fts],
      filter: search_filters
    }.compact
    terms.blank? ? nil : terms
  end

  def search_pagn
    params.slice(:per_page, :page)
  end
end
