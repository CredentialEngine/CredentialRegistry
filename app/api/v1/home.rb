require 'exceptions'
require 'v1/envelopes'
require 'render_markdown'

module API
  module V1
    # Home page
    class Home < Grape::API
      # return HTML instead of json
      content_type :html, 'text/html'
      format :html

      desc 'Homepage'
      get '/readme' do
        RenderMarkdown.new('README').to_html
      end
    end
  end
end
