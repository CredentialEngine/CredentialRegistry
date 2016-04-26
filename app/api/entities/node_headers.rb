module API
  module Entities
    # Presenter for the node headers added automatically
    class NodeHeaders < Grape::Entity
      expose :resource_digest
      expose :versions,
             unless: :is_version,
             using: API::Entities::Version,
             documentation: { is_array: true,
                              desc: 'Versions belonging to the envelope' }
      expose :created_at,
             documentation: { type: 'dateTime',
                              desc: 'Creation date' }
      expose :updated_at,
             documentation: { type: 'dateTime',
                              desc: 'Last modification date' }
      expose :deleted_at,
             documentation: { type: 'dateTime',
                              desc: 'Deletion date' }
    end
  end
end
