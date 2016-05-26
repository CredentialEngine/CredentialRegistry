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

  def location(file)
    "https://s3.us.archive.org/#{current_item}/#{File.basename(file)}"
  end

  def current_item
    'learning-registry-test'
  end

  private

  def headers
    {
      content_type: 'application/json',
      authorization: "LOW #{ENV['INTERNET_ARCHIVE_ACCESS_KEY']}:"\
                         "#{ENV['INTERNET_ARCHIVE_SECRET_KEY']}"
    }
  end
end
