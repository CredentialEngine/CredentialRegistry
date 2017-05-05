require 'aws-sdk'

# Provides utility methods for aws s3 file management
class S3
  attr_reader :bucket

  def initialize(bucket)
    if bucket.blank?
      raise MR::BackupItemMissingError, 'Backup bucket is missing'
    end

    @bucket = Aws::S3::Resource.new.bucket(bucket)
  end

  def name
    's3'
  end

  def upload(file)
    s3_object(file).upload_file(file)
  end

  def delete(file)
    s3_object(file).delete
  end

  #
  # Returns the full path of the newly created file
  #
  def retrieve(file)
    destination = "tmp/dumps/#{file}"
    s3_object(file).download_file(destination)
    destination
  end

  #
  # The interface dictates that we return a location, this is unnecessary for
  # s3
  #
  def location(file)
    File.basename(file)
  end

  private

  def s3_object(file)
    bucket.object(File.basename(file))
  end
end
