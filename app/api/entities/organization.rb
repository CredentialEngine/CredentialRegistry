module API
  module Entities
    # Presenter for organizations
    class Organization < Grape::Entity
      expose :id,
             documentation: { type: 'string',
                              desc: 'Unique identifier (in UUID format)' }
      expose :name,
             documentation: { type: 'string',
                              desc: 'Name of this organization' }

      expose :description,
             documentation: { type: 'string',
                              desc: 'Description of this organization' }
    end
  end
end
