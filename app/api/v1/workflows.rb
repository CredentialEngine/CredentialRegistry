require 'mountable_api'
require 'helpers/shared_helpers'

module API
  module V1
    # Endpoints for operational workflows (called by Argo Workflows)
    class Workflows < MountableAPI
      mounted do
        helpers SharedHelpers

        before do
          authenticate!
        end

        resource :workflows do
          desc 'Indexes all S3 JSON-LD graphs to Elasticsearch. ' \
               'S3 is treated as the source of truth. ' \
               'Called by Argo Workflows for orchestration.'
          post 'index-all-s3-to-es' do
            authorize :workflow, :trigger?

            bucket_name = ENV['ENVELOPE_GRAPHS_BUCKET']
            error!({ error: 'ENVELOPE_GRAPHS_BUCKET not configured' }, 500) unless bucket_name

            es_address = ENV['ELASTICSEARCH_ADDRESS']
            error!({ error: 'ELASTICSEARCH_ADDRESS not configured' }, 500) unless es_address

            s3 = Aws::S3::Resource.new(region: ENV['AWS_REGION'].presence)
            bucket = s3.bucket(bucket_name)

            errors = {}
            processed = 0
            skipped = 0

            bucket.objects.each do |object|
              next unless object.key.end_with?('.json')

              processed += 1

              begin
                IndexS3GraphToEs.call(object.key)
              rescue StandardError => e
                errors[object.key] = "#{e.class}: #{e.message}"
              end
            end

            status_code = errors.empty? ? 200 : 207

            status status_code
            {
              message: errors.empty? ? 'Indexing completed successfully' : 'Indexing completed with errors',
              processed: processed,
              errors_count: errors.size,
              errors: errors.first(100).to_h
            }
          end
        end
      end
    end
  end
end
