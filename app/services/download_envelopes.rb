# Dumps an envelope community's envelopes into a ZIP archive and uploads it to S3
class DownloadEnvelopes # rubocop:todo Metrics/ClassLength
  attr_reader :envelope_download, :updated_at

  delegate :envelope_community, to: :envelope_download

  def initialize(envelope_download)
    @envelope_download = envelope_download
    @updated_at = envelope_download.started_at
  end

  def self.call(envelope_download:)
    new(envelope_download).run
  end

  def bucket
    ENV.fetch('ENVELOPE_DOWNLOADS_BUCKET')
  end

  def create_or_update_entries
    FileUtils.mkdir_p(dirname)

    log('Adding recently published envelopes into the dump')

    published_envelopes.find_each do |envelope|
      File.write(
        File.join(dirname, "#{envelope.envelope_ceterms_ctid}.json"),
        API::Entities::Envelope.represent(envelope).to_json
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
    return unless envelope_download.url?

    log("Downloading the existing dump from #{envelope_download.url}")

    File.open(filename, 'wb') do |file|
      URI.parse(envelope_download.url).open do |data|
        file.write(data.read)
      end
    end

    log("Unarchiving the downloaded dump into #{dirname}")
    system("unzip -qq #{filename} -d #{dirname}", exception: true)
  rescue StandardError => e
    Airbrake.notify(e)
  end

  def destroy_envelope_events
    @deleted_envelope_ctids = envelope_community
                              .versions
                              .where(event: 'destroy')
                              .where('created_at >= ?', updated_at)
  end

  def filename
    @filename ||= "#{dirname}.zip"
  end

  def log(message)
    MR.logger.info(message)
  end

  def published_envelopes
    @published_envelopes = begin
      envelopes = envelope_community
                  .envelopes
                  .not_deleted
                  .includes(:envelope_community, :organization, :publishing_organization)

      envelopes.where!('updated_at >= ?', updated_at) if updated_at
      envelopes
    end
  end

  def region
    ENV.fetch('AWS_REGION')
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

  def run # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
    envelope_download.update!(
      internal_error_backtrace: [],
      internal_error_message: nil,
      started_at: Time.current,
      status: :in_progress
    )

    envelope_download.with_lock do
      if up_to_date?
        log('The dump is up to date.')
        return
      end

      download_file
      create_or_update_entries
      remove_entries
      envelope_download.url = upload_file
    rescue StandardError => e
      Airbrake.notify(e)
      envelope_download&.internal_error_backtrace = e.backtrace
      envelope_download&.internal_error_message = e.message
    ensure
      log('Deleting intermediate files.')
      FileUtils.rm_rf(dirname)
      FileUtils.rm_f(filename)
      envelope_download.update!(finished_at: Time.current, status: :finished)
      log('Finished.')
    end
  end

  def up_to_date?
    published_envelopes.none? && destroy_envelope_events.none?
  end

  def upload_file
    log('Archiving the updated dump.')

    system(
      "find #{dirname} -type f -print | zip -FSjqq #{filename} -@",
      exception: true
    )

    log('Uploading the updated dump to S3.')

    object = Aws::S3::Resource.new(region:).bucket(bucket).object(filename)
    object.upload_file(filename)
    object.public_url
  end
end
