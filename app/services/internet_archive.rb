require 'rest_client'

# Provides utility methods for archive.org file management
class InternetArchive
  attr_reader :item

  def initialize(item)
    raise MR::BackupItemMissingError, 'Backup item is missing' if item.blank?

    @item = item
  end

  def name
    'archive.org'
  end

  def upload(file)
    RestClient::Request.execute(
      method: :put,
      url: location(file),
      headers: headers,
      payload: File.read(file),
      timeout: 60 * 5
    )
  end

  def delete(file)
    RestClient.delete(location(file), headers)
  end

  #
  # Retrieves the remote dump file and stores it using a temporary file
  # Returns the full path of the newly created file
  #
  def retrieve(dump_location)
    Tempfile.open('dump') do |file|
      IO.copy_stream(URI.parse(dump_location).open, file)

      file.path
    end
  end

  #
  # Not using HTTPS for now because archive.org usually redirects to HTTP, even
  # if the original request was done using HTTPS, and that gives some problems
  # when streaming the download
  #
  def location(file)
    "http://s3.us.archive.org/#{item}/#{File.basename(file)}"
  end

  private

  def headers
    {
      'x-archive-auto-make-bucket' => '1', # Create the bucket if it does not exist
      content_type: 'application/gzip',
      authorization: "LOW #{ENV['INTERNET_ARCHIVE_ACCESS_KEY']}:"\
                         "#{ENV['INTERNET_ARCHIVE_SECRET_KEY']}"
    }
  end
end
