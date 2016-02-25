require 'v1/base'

module API
  # Main base class that defines all API versions
  class Base < Grape::API
    mount API::V1::Base

    add_swagger_documentation
  end
end
