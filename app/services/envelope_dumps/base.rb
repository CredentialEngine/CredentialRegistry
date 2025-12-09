module EnvelopeDumps
  # Dumps an envelope community's envelopes or graphs into a ZIP file and uploads it to S3
  class Base # rubocop:todo Metrics/ClassLength
    attr_reader :envelope_download, :last_dumped_at

    delegate :envelope_community, :url, to: :envelope_download

    def initialize(envelope_download, last_dumped_at)
      @envelope_download = envelope_download
      @last_dumped_at = last_dumped_at
    end

    def bucket
      @bucket ||= Aws::S3::Resource
                  .new(region: ENV.fetch('AWS_REGION'))
                  .bucket(bucket_name)
    end

    def bucket_name
      raise NotImplementedError
    end

    def build_content(_envelope)
      raise NotImplementedError
    end

    def create_or_update_entries
      FileUtils.mkdir_p(dirname)

      log('Adding recently published envelopes into the dump')

      published_envelopes.find_each do |envelope|
        File.write(
          File.join(dirname, "#{envelope.envelope_ceterms_ctid}.json"),
          build_content(envelope).to_json
        )
      end
    end

    def dirname
      @dirname ||= [
        envelope_community.name,
        Time.current.to_i,
        SecureRandom.hex
      ].join('_')
    end

    def download_file # rubocop:todo Metrics/AbcSize
      return unless url.present?

      log("Downloading the existing dump from #{url}")
      previous_filename = url.split('/').last
      object = bucket.object(previous_filename)
      object.get(response_target: filename)

      log("Unarchiving the downloaded dump into #{dirname}")
      system("unzip -qq #{filename} -d #{dirname}", exception: true)
    rescue StandardError => e
      Airbrake.notify(e)
    end

    def destroy_envelope_events
      @destroy_envelope_events ||= envelope_community
                                   .versions
                                   .where(event: 'destroy')
                                   .where('created_at >= ?', last_dumped_at)
    end

    def filename
      @filename ||= "#{dirname}.zip"
    end

    def log(message)
      MR.logger.info(message)
    end

    def published_envelopes
      @published_envelopes ||= begin
        envelopes = envelope_community
                    .envelopes
                    .not_deleted
                    .includes(:envelope_community, :organization, :publishing_organization)

        envelopes.where!('updated_at >= ?', last_dumped_at) if last_dumped_at
        envelopes
      end
    end

    def remove_entries
      log('Removing recently deleted envelopes from the dump')

      destroy_envelope_events.select(:id, :envelope_ceterms_ctid).find_each do |event|
        FileUtils.remove_file(
          File.join(dirname, "#{event.envelope_ceterms_ctid}.json"),
          true
        )
      end
    end

    def run
      if up_to_date?
        log('The dump is up to date.')
        return
      end

      download_file
      create_or_update_entries
      remove_entries
      upload_file
    ensure
      log('Deleting intermediate files.')
      FileUtils.rm_rf(dirname)
      FileUtils.rm_f(filename)
      log('Finished.')
    end

    def up_to_date?
      url.present? && published_envelopes.none? && destroy_envelope_events.none?
    end

    def upload_file
      log('Archiving the updated dump.')

      system(
        "find #{dirname} -type f -print | zip -FSjqq #{filename} -@",
        exception: true
      )

      log('Uploading the updated dump to S3.')

      object = bucket.object(filename)
      object.upload_file(filename)
      object.public_url
    end
  end
end
