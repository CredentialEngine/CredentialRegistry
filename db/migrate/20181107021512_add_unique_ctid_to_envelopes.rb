class AddUniqueCtidToEnvelopes < ActiveRecord::Migration
  def change
    # Fix envelope_ceterms_ctid
    execute <<~SQL
      update
        envelopes
      set
        envelope_ceterms_ctid = reverse(split_part(reverse(processed_resource->>'@id'), '/', 1))
      where
        deleted_at is null
    SQL

    # Fix duplicates
    dupes = Envelope.find_by_sql <<~SQL
      select * from (
         select
           duplicates.*,
             row_number() over (partition by envelope_ceterms_ctid order by created_at desc) row_num
           from  (
             select * from envelopes where envelope_ceterms_ctid in (
               select envelope_ceterms_ctid
               from envelopes
               group by envelope_ceterms_ctid
               having count(*)  > 1
               order by count(*) desc
             )
           ) as duplicates
         ) dupes
      where row_num > 1
    SQL

    puts "Fixing #{dupes.count} duplicates."
    dupes.each do |envelope|
      envelope.mark_as_deleted!
    end

    add_index :envelopes, [:envelope_ceterms_ctid], unique: true, where: 'deleted_at is null'
  end
end
