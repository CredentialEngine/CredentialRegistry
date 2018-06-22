class AddLookupIdToEnvelopes < ActiveRecord::Migration
  def up
    add_column :envelopes, :lookup_id, :string, index: true

    Envelope.all.each.with_index do |envelope, i|
      envelope.update_column(:lookup_id, envelope.construct_lookup_id)
      print '.' if i % 1 == 10
    end

    puts

    execute('CREATE INDEX envelopes_lookup_id_idx ON envelopes ' \
            '(lower(lookup_id));')
  end

  def down
    remove_column :envelopes, :lookup_id
  end
end
