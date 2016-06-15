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
  # Retrieves the remote dump file and stores it using a temporary file
  # Returns the full path of the newly created file
  #
  def retrieve(dump_location)
    Tempfile.open('dump') do |file|
      IO.copy_stream(open(dump_location), file)

      file.path
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
    ENV['INTERNET_ARCHIVE_ITEM']
  end

  private

  def headers
    {
      content_type: 'application/gzip',
      authorization: "LOW #{ENV['INTERNET_ARCHIVE_ACCESS_KEY']}:"\
                         "#{ENV['INTERNET_ARCHIVE_SECRET_KEY']}"
    }
  end
end
