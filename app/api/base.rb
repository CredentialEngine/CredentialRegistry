require 'v1/base'

module API
  # Main base class that defines all API versions
  class Base < Grape::API
    mount API::V1::Base

    # https://github.com/ruby-grape/grape-swagger/issues/267
    # TODO: enable swagger documentation again when fixed or workaround is found
    # add_swagger_documentation info: {
    #   title: 'Learning Registry API',
    #   description: 'Documentation for the new API endpoints',
    #   contact_name: 'Learning Registry',
    #   contact_email: 'learningreg-dev@googlegroups.com',
    #   contact_url: 'http://learningregistry.org',
    #   license: 'Apache License, Version 2.0',
    #   license_url: 'http://www.apache.org/licenses/LICENSE-2.0'
    # }
  end
end
