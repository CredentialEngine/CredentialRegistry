# Provides utility methods for archive.org file management
# For now it's just a placeholder returning simple values
class InternetArchive
  def self.current_item
    'node-1234'
  end

  def self.location(file)
    "https://s3.us.archive.org/#{current_item}/#{file}"
  end
end
