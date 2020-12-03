module API
  module Entities
    # Presenter for the node headers added automatically
    class NodeHeaders < Grape::Entity
      expose :resource_digest
      expose :versions,
             as: :revision_history,
             unless: :is_version,
             using: API::Entities::Version,
             documentation: { is_array: true,
                              desc: 'Revision history of the envelope' }
      expose :created_at,
             documentation: { type: 'dateTime',
                              desc: 'Creation date' }
      expose :updated_at,
             documentation: { type: 'dateTime',
                              desc: 'Last modification date' }
      expose :deleted_at,
             documentation: { type: 'dateTime',
                              desc: 'Deletion date' }

      expose :owned_by,
             documentation: { type: 'string',
                              desc: 'Owner of the envelope' }

      expose :published_by,
             documentation: { type: 'string',
                              desc: 'Publisher of the envelope' }
    end
  end
end
