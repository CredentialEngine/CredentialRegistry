# Stores an administrative public key that is entitled to update/delete any
# envelope
class AdministrativeAccount < ActiveRecord::Base
  validates :public_key, presence: true, uniqueness: true
end
