require 'active_support/concern'
require 'schema_config'

# When included define the search properties for the model
module Searchable
  extend ActiveSupport::Concern

  included do
    include PgSearch

    pg_search_scope :search,
                    against: [:fts_tsearch, :fts_trigram],
                    using: {
                      tsearch: {
                        tsvector_column: 'fts_tsearch_tsv',
                        normalization: 2
                      },
                      trigram: {
                        only: :fts_trigram,
                        threshold: 0.1
                      }
                    },
                    ranked_by: ':trigram + 0.25 * :tsearch'

    before_save :set_fts_attrs, on: [:create, :update]
    before_save :set_resource_type, on: [:create, :update]

    # Build the fts utility fields.
    # These fields are defined on the corresponding 'community/search.json'
    # config file.
    def set_fts_attrs
      if search_cfg.present?
        self.fts_tsearch = joined_resource_fields search_cfg['full']
        self.fts_trigram = joined_resource_fields search_cfg['partial']
      end
    end

    # get the search configuration schema
    def search_cfg
      @search_cfg ||= begin
        SchemaConfig.new(resource_schema_name).config.try(:[], 'fts') || {}
      rescue MR::SchemaDoesNotExist
        {}
      end
    end

    def joined_resource_fields(fields)
      fields ||= []
      fields.map { |prop| processed_resource[prop] }.compact.join("\n")
    end

    def set_resource_type
      if resource_data?
        self.resource_type = SchemaConfig.resource_type_for(self)
      end
    end
  end
end
