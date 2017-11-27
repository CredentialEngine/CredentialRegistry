module API
  module Entities
    # Presenter for publishers
    class Publisher < Grape::Entity
      expose :id,
             documentation: { type: 'string',
                              desc: 'Unique identifier (in UUID format)' }
      expose :name,
             documentation: { type: 'string',
                              desc: 'Name of this publisher' }

      expose :description,
             documentation: { type: 'string',
                              desc: 'Description of this publisher' }

      expose :contact_info,
             documentation: { type: 'string',
                              desc: 'Contact information of this publisher' }
    end
  end
end
