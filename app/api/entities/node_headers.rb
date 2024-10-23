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

      def created_at
        Time.zone.parse(object.created_at) if object.created_at?
      end

      def deleted_at
        Time.zone.parse(object.deleted_at) if object.deleted_at?
      end

      def updated_at
        Time.zone.parse(object.updated_at) if object.updated_at?
      end
    end
  end
end
