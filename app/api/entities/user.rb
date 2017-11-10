module API
  module Entities
    # Presenter for users
    class User < Grape::Entity
      expose :id,
             documentation: { type: 'string',
                              desc: 'Unique identifier' }
      expose :email,
             documentation: { type: 'string',
                              desc: 'Email of this user' }
    end
  end
end
