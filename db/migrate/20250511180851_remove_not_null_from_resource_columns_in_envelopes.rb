class RemoveNotNullFromResourceColumnsInEnvelopes < ActiveRecord::Migration[8.0]
  def up
    change_column_null :envelopes, :resource, true
    change_column_null :envelopes, :resource_public_key, true
  end
end
