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
  # Retrieves the remote dump file, stores it in a temporary file and then
  # returns an enumerator, useful to stream the contents externally
  #
  def retrieve(dump)
    Tempfile.open('dump') do |f|
      f.write(RestClient.get(dump.location, headers))

      File.foreach(f)
    end
  end

  def location(file)
    "https://s3.us.archive.org/#{current_item}/#{File.basename(file)}"
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
