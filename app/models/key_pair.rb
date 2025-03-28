# RSA key pair used for server-side signing
class KeyPair < ActiveRecord::Base
  SECRET_KEY = [ENV.fetch('ENCRYPTED_PRIVATE_KEY_SECRET')].pack('H*')[0..31]

  enum :status, { active: 1 }

  belongs_to :organization

  before_create :generate_keys

  def private_key
    Encryptor.decrypt(value: encrypted_private_key, key: SECRET_KEY, iv: iv)
  end

  private

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def generate_keys
    dir_path = MR.root_path.join('tmp', 'keys', organization_id.to_s)
    FileUtils.mkdir_p(dir_path)

    pem_path = "#{dir_path}id_rsa.pem"
    private_key_path = "#{dir_path}id_rsa"
    public_key_path = "#{dir_path}id_rsa.pub"

    unless system("ssh-keygen -f #{escape(private_key_path)} -P '' -t rsa -m pem -q")
      raise 'RSA key pair generation failed'
    end

    unless system("ssh-keygen -f #{escape(public_key_path)} -e -m pem > #{escape(pem_path)} -q")
      raise 'Public key conversion to PEM format failed'
    end

    self.iv = SecureRandom.random_bytes(12)
    self.encrypted_private_key = Encryptor.encrypt(
      value: File.read(private_key_path),
      key: SECRET_KEY,
      iv: iv
    )
    self.public_key = File.read(pem_path)
  ensure
    FileUtils.rm_rf(dir_path)
  end

  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  def escape(path)
    Shellwords.escape(path)
  end
end
