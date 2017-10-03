require 'active_support/concern'

# When included define the search properties for the model
module Searchable
  extend ActiveSupport::Concern

  included do
    include PgSearch

    pg_search_scope :search,
                    against: %i[fts_tsearch fts_trigram],
                    using: {
                      tsearch: {
                        tsvector_column: 'fts_tsearch_tsv',
                        normalization: 2
                      },
                      trigram: {
                        only: :fts_trigram,
                        threshold: 0.3
                      }
                    },
                    ranked_by: ':trigram + 0.25 * :tsearch'

    before_save :set_fts_attrs, on: %i[create update]
    before_save :set_resource_type, on: %i[create update]

    # Build the fts utility fields.
    # These fields are defined on the corresponding 'community/search.json'
    # config file.
    def set_fts_attrs
      return unless search_cfg.present?

      self.fts_tsearch = joined_resource_fields search_cfg['full']
      self.fts_trigram = joined_resource_fields search_cfg['partial']
    end

    # get the search configuration schema
    def search_cfg
      @search_cfg ||= begin
        community.config(resource_type).try(:[], 'fts') || {}
      rescue MR::SchemaDoesNotExist
        {}
      end
    end

    def joined_resource_fields(paths)
      (paths || []).map do |path|
        value = JsonPath.on(processed_resource_before_type_cast, path).first
        next if value.blank?
        value.gsub(/[:?]/, ' ')
      end.compact.join("\n")
    end

    def set_resource_type
      self.resource_type = community.resource_type_for(self) if resource_data?
    end
  end
end
