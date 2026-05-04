class EnvelopeResourceSyncEvent < ActiveRecord::Base
  ACTIONS = {
    upsert: 0,
    delete: 1
  }.freeze

  belongs_to :envelope_community

  validates :envelope_community_id, :resource_id, :action, presence: true
  validates :action, inclusion: { in: ACTIONS.values }

  def delete?
    action == ACTIONS[:delete]
  end

  def upsert?
    action == ACTIONS[:upsert]
  end

  def action_name
    ACTIONS.key(action).to_s
  end
end
