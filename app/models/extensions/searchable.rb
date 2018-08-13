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

    # Build the fts utility fields.
    # These fields are defined on the corresponding 'community/search.json'
    # config file.
    def set_fts_attrs
      return unless search_configuration.present?
      self.fts_tsearch = joined_resource_fields(search_configuration.full)
      self.fts_trigram = joined_resource_fields(search_configuration.partial)
    end

    def joined_resource_fields(fts_paths)
      (fts_paths || []).map do |fts_path|
        value = JsonPath.on(processed_resource, fts_path).first
        next if value.blank?
        value.gsub(/[:?]/, ' ')
      end.compact.join("\n")
    end
  end
end
