require 'active_support/concern'

# When included define the search properties for the model
module Searchable
  extend ActiveSupport::Concern

  included do
    include PgSearch::Model

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

    before_save :set_fts_attrs

    # Build the fts utility fields.
    # These fields are defined on the corresponding 'community/search.json'
    # config file.
    def set_fts_attrs
      return unless search_configuration.present?

      self.fts_tsearch = joined_resource_fields(search_configuration.full)
      self.fts_trigram = joined_resource_fields(search_configuration.partial)
    end

    def joined_resource_fields(fts_paths)
      (fts_paths || []).filter_map do |fts_path|
        value = JsonPath.on(processed_resource, fts_path).first
        next if value.blank?

        extract_pieces(value)
      end.join("\n")
    end

    def extract_pieces(value)
      # We have three patterns:
      #   String: { "ceterms:name": "Test" }
      #   Language map with string: { "ceterms:name": { "en": "Test" } }
      #   Language map with array: { "ceterms:name": { "en": ["Test 1"] } }

      # String pattern
      return value.gsub(/[:?]/, ' ') if value.is_a? String

      # Language map
      if value.is_a? Hash
        pieces = []
        value.each_value do |piece|
          if piece.is_a? String # Language map with string
            pieces << piece
          elsif piece.is_a? Array # Language map with array
            pieces.push(*piece)
          end
        end
        return pieces.map { |p| p.gsub(/[:?]/, ' ') }.join("\n")
      end

      MR.logger.error("Unknown entity in search field: #{value}")
      nil
    end
  end
end
