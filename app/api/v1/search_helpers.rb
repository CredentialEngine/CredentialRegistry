# Search specific helpers
module SearchHelpers
  extend Grape::API::Helpers

  # Build search filters.
  # Return:
  #  - [Hash] compact hash of parsed filters
  #  - [Nil] if the filters are empty, we return nil
  def search_filters
    filters = {
      community: term_for_community,
      envelope_type: params[:type],
      resource_schema_name: term_for_resource_type
    }.compact
    filters.blank? ? nil : filters
  end

  # Term for the community filter.
  # Can come from the regular url param 'envelope_community'
  # or from the query param 'community'
  def term_for_community
    community || params[:community].try(:underscore)
  end

  # Term for the resource_type filter.
  # Can come from either the url or a query param.
  # It's built joining the community name and the type.
  # i.e: for the url: '/api/credential-registry/credentials/search'
  #      we have:     'credential_registry/credential'
  def term_for_resource_type
    if params[:resource_type].present?
      resource_type = params[:resource_type].downcase.singularize
      [term_for_community, resource_type].compact.join('/')
    end
  end

  # Build the date_range search filter.
  # Accepts the query params 'from' and 'until'
  # Return:
  #  - [Hash] compact hash of th date_range filter
  #  - [Nil] if the filters are empty, we return nil
  def search_date_range
    date_range = {
      from: params[:from],
      until: params[:until]
    }.compact
    date_range.blank? ? nil : date_range
  end

  # Build search terms to be used on the QueryBuilder
  # Return:
  #  - [Hash] compact hash of the nested terms.
  #  - [Nil] if the filters are empty, we return nil
  #          (in this we will do a "match_all" query)
  def search_terms
    terms = {
      fts: params[:fts], # full-text search
      date: search_date_range, # date range filters
      must: search_filters # envelope filters
    }.compact
    terms.blank? ? nil : terms
  end

  # search's pagination params, used as options for the QueryBuilder
  # Return: [Hash] only the corresponding keys from the params
  def search_pagn
    params.slice(:per_page, :page)
  end
end
