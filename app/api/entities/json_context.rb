module API
  module Entities
    # Presenter for JsonContext
    class JsonContext < Grape::Entity
      expose :context,
             documentation: { type: 'object',
                              desc: 'The payload of the context' }
      expose :url,
             documentation: { type: 'string',
                              desc: 'The URL of the context' }
    end
  end
end
