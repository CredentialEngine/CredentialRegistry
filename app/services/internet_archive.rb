require 'rest_client'

# Provides utility methods for archive.org file management
class InternetArchive
  def name
    'archive.org'
  end

  def upload(file)
    RestClient.put(location(file), File.read(file), headers)
  end

  def delete(file)
    RestClient.delete(location(file), headers)
  end

  #
  # Retrieves the remote dump file, stores it using a temporary file and then
  # returns an enumerator, useful to stream the contents externally
  #
  def retrieve(dump)
    Tempfile.open('dump') do |file|
      IO.copy_stream(open(dump.location), file)

      File.foreach(file)
    end
  end

  #
  # Not using HTTPS for now because archive.org usually redirects to HTTP, even
  # if the original request was done using HTTPS, and that gives some problems
  # when streaming the download
  #
  def location(file)
    "http://s3.us.archive.org/#{current_item}/#{File.basename(file)}"
  end

  def current_item
    'learning-registry-test'
  end

  private

  def headers
    {
      content_type: 'text/plain',
      authorization: "LOW #{ENV['INTERNET_ARCHIVE_ACCESS_KEY']}:"\
                         "#{ENV['INTERNET_ARCHIVE_SECRET_KEY']}"
    }
  end
end
