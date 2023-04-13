require 'json_context'

namespace :json_contexts do
  desc 'Updates the JSON context specs used for indexing envelope resources'
  task update: :cer_environment do
    urls = Envelope.distinct.pluck(Arel.sql("processed_resource->>'@context'"))

    urls.each do |url|
      next if url.blank?

      puts "Updating context for #{url}"
      context = JSON.parse(RestClient.get(url).body)
      json_context = JsonContext.find_or_initialize_by(url:)
      json_context.update!(context:)
      puts 'Updated!'
    end
  end
end
