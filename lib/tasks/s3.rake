namespace :s3 do
  desc 'Index all S3 JSON-LD graphs to Elasticsearch (S3 as source of truth)'
  task index_all_to_es: :environment do
    require 'benchmark'
    require 'json'

    bucket_name = ENV['ENVELOPE_GRAPHS_BUCKET']
    abort 'ENVELOPE_GRAPHS_BUCKET environment variable is not set' unless bucket_name

    es_address = ENV['ELASTICSEARCH_ADDRESS']
    abort 'ELASTICSEARCH_ADDRESS environment variable is not set' unless es_address

    $stdout.sync = true

    s3 = Aws::S3::Resource.new(region: ENV['AWS_REGION'].presence)
    bucket = s3.bucket(bucket_name)

    errors = {}
    processed = 0
    skipped = 0

    puts "Starting S3 to ES indexing from bucket: #{bucket_name}"
    puts "Elasticsearch address: #{es_address}"
    puts "Counting objects..."

    # Count total objects for progress reporting
    total = bucket.objects.count { |obj| obj.key.end_with?('.json') }
    puts "Found #{total} JSON files to index"
    puts "Started at #{Time.now.utc}"

    time = Benchmark.measure do
      bucket.objects.each do |object|
        next unless object.key.end_with?('.json')

        processed += 1

        begin
          IndexS3GraphToEs.call(object.key)
        rescue StandardError => e
          errors[object.key] = "#{e.class}: #{e.message}"
        end

        # Progress every 100 records
        if (processed % 100).zero?
          puts "Progress: processed=#{processed}/#{total} errors=#{errors.size} skipped=#{skipped}"
        end
      end
    end

    puts time
    puts "Finished at #{Time.now.utc} - processed=#{processed}, errors=#{errors.size}"

    # Write errors to file
    if errors.any?
      File.write('/tmp/s3_index_errors.json', JSON.pretty_generate(errors))
      puts "Wrote /tmp/s3_index_errors.json (#{errors.size} entries)"

      # Upload errors to S3
      begin
        error_bucket = ENV['S3_ERRORS_BUCKET'] || bucket_name
        error_key = "errors/s3-index-errors-#{Time.now.utc.strftime('%Y%m%dT%H%M%SZ')}.json"
        s3_client = Aws::S3::Client.new(region: ENV['AWS_REGION'].presence)
        s3_client.put_object(
          bucket: error_bucket,
          key: error_key,
          body: File.open('/tmp/s3_index_errors.json', 'rb')
        )
        puts "Uploaded errors to s3://#{error_bucket}/#{error_key}"
      rescue StandardError => e
        warn "Failed to upload errors to S3: #{e.class}: #{e.message}"
      end

      warn "Encountered #{errors.size} errors. Sample: #{errors.to_a.first(5).to_h.inspect}"
      exit 1
    end
  end
end
