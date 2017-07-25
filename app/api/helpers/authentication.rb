require 'warden'
require 'api_consumer'

Warden::Strategies.add(:api_token) do
  def authenticate!
    uid = env['grape.request'].headers['Http-Auth-Token']

    api_consumer = ApiConsumer.find_by(uid: uid)
    if api_consumer.present?
      success!(api_consumer)
    else
      throw :warden
    end
  end
end
