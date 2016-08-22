require 'active_support/concern'
require 'search/repository'
require 'search/document'

# When included define the search properties for the model
module Searchable
  extend ActiveSupport::Concern

  included do
    attr_accessor :skip_indexing

    after_commit :index_document, on: [:create, :update], if: :should_index?
    after_commit :delete_document, on: :destroy, if: :should_index?

    def index_document
      Search::Document.build(self).index!
      # rescue Faraday::ConnectionFailed; end
    end

    def delete_document
      Search::Document.build(self).delete!
      # rescue Faraday::ConnectionFailed; end
    end

    def self.search_repo
      @search_repo ||= Search::Repository.new
    end

    def search_index_exists?
      self.class.search_repo.index_exists?
    end

    def should_index?
      # we only index if the attr skip_indexing is falsy
      # and the search index exists on ES
      !skip_indexing && search_index_exists?
    end
  end
end
