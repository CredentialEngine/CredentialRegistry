require 'active_support/concern'
require 'search/schema'

# When included define the search properties for the model
module Searchable
  extend ActiveSupport::Concern

  included do
    include PgSearch

    pg_search_scope :search,
                    against: [:fts_tsearch, :fts_trigram],
                    using: {
                      tsearch: {
                        # prefix: true,
                        tsvector_column: 'fts_tsearch_tsv',
                        normalization: 2
                      },
                      trigram: {
                        threshold: 0.1,
                        only: :fts_trigram
                      }
                    },
                    ranked_by: ':trigram + 0.25 * :tsearch'

    before_save :set_fts_attrs, on: [:create, :update]

    # Build the fts utility fields.
    # These fields are defined on the corresponding 'community/search.json'
    # config file.
    def set_fts_attrs
      return '' if search_schema.nil?

      fts_config = search_schema.fetch('fts', {})
      self.fts_tsearch = joined_resource_fields fts_config['full']
      self.fts_trigram = joined_resource_fields fts_config['partial']
    end

    # get the search configuration schema
    def search_schema
      @search_schema ||= ::Search::Schema.new(resource_schema_name).schema
    end

    def joined_resource_fields(fields)
      fields ||= []
      fields.map { |prop| processed_resource[prop] }.compact.join("\n")
    end
  end
end
