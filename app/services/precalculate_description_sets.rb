# Creates, updates, or deletes description sets built from CTDL data
class PrecalculateDescriptionSets
  class Reference
    attr_reader :property

    def initialize(value, index)
      @incoming = value.starts_with?('<')
      @index = index
      @property = value.gsub(/[<>]/, '').squish
    end

    def left_column
      @incoming ? 'subresource_uri' : 'resource_uri'
    end

    def right_column
      @incoming ? 'resource_uri' : 'subresource_uri'
    end

    def table_alias
      "ref#{@index + 1}"
    end
  end

  class << self
    def process(envelope)
      if envelope.deleted?
        delete_description_sets(envelope)
        return
      end

      envelope.processed_resource.fetch('@graph', []).each do |resource|
        resource_id = resource.fetch('@id')
        resource_type = resource.fetch('@type')

        reverse_maps = maps.select do |map|
          target_types = map.fetch(:target_types)
          next true if target_types.empty?

          target_types.include?(resource_type)
        end

        description_sets = maps
          .select { |map| map.fetch(:subject_types).include?(resource_type) }
          .map { |map| build_description_sets(map, resource_id) }
          .flatten

        description_sets += reverse_maps
          .map { |map| build_description_sets(map, resource_id, reverse: true) }
          .flatten

        insert_description_sets(description_sets)
      end
    end

    def process_all
      maps.each_with_index do |map, index|
        insert_description_sets(build_description_sets(map))
      end
    end

    private

    def build_description_sets(map, resource_id = nil, reverse: false)
      path = map.fetch(:property_path)
      subject_types = map.fetch(:subject_types).map { |t| "'#{t}'" }.join(', ')
      target_types = map.fetch(:target_types).map { |t| "'#{t}'" }.join(', ')

      refs = path.scan(/[<>]\s*[^\s<>]+/).each_with_index.map do |part, index|
        Reference.new(part, index)
      end

      query = <<~SQL
        SELECT subject.envelope_community_id,
               subject.envelope_resource_id,
               subject."ceterms:ctid" ceterms_ctid,
               array_agg(DISTINCT target."@id") uris
        FROM indexed_envelope_resources subject
      SQL

      [nil, *refs].each_cons(2) do |left, right|
        left_column = left&.right_column || '"@id"'
        left_table = left&.table_alias || 'subject'
        right_column = right.left_column
        right_table = right.table_alias

        query += <<~SQL
          INNER JOIN indexed_envelope_resource_references #{right_table}
          ON #{left_table}.#{left_column} = #{right_table}.#{right_column}
          AND #{right_table}.path = '#{right.property}'
        SQL
      end

      last_ref = refs.last

      query += <<~SQL
        INNER JOIN indexed_envelope_resources target
        ON #{last_ref.table_alias}.#{last_ref.right_column} = target."@id"
        WHERE subject."@type" IN (#{subject_types})
      SQL

      if resource_id
        query += <<~SQL
          AND #{reverse ? 'target' : 'subject'}."@id" = '#{resource_id}'
        SQL
      end

      if target_types.present?
        query += <<~SQL
          AND target."@type" IN (#{target_types})
        SQL
      end

      query += <<~SQL
        GROUP BY subject.envelope_community_id,
                 subject.envelope_resource_id,
                 subject."ceterms:ctid"
      SQL

      connection = ActiveRecord::Base.connection
      result = connection.execute(query)

      result.type_map = PG::BasicTypeMapForResults.new(
        connection.raw_connection
      )

      description_sets = result.map do |row|
        next unless row['ceterms_ctid'].present?

        description_set = DescriptionSet.find_or_initialize_by(
          ceterms_ctid: row.fetch('ceterms_ctid'),
          envelope_community_id: row.fetch('envelope_community_id'),
          path: map[:path]
        )

        description_set.envelope_resource_id = row.fetch('envelope_resource_id')

        if reverse
          description_set.uris |= row.fetch('uris')
        else
          description_set.uris = row.fetch('uris')
        end

        description_set
      end

      description_sets.compact
    end

    def delete_description_sets(envelope)
      DescriptionSet.where(id: envelope.description_sets).delete_all

      resource_ids = envelope
        .envelope_resources
        .pluck(:resource_id)
        .map { |id| "'#{id}'"}
        .join(', ')

      DescriptionSet.connection.execute(<<~COMMAND)
        WITH affected AS (
          SELECT id, uri
          FROM description_sets, unnest(uris) uri
          WHERE uri IN (#{resource_ids})
        ),
        updated AS (
          SELECT id, uri
          FROM affected
          WHERE uri NOT IN (#{resource_ids})
        )
        UPDATE description_sets
        SET uris = array_remove(t.uris, NULL)
        FROM (
          SELECT affected.id, array_agg(updated.uri) uris
          FROM affected
          LEFT OUTER JOIN updated
          ON affected.id = updated.id
          GROUP BY affected.id
        ) t
        WHERE description_sets.id = t.id;
      COMMAND

      DescriptionSet.where(uris: []).delete_all
    end

    def insert_description_sets(description_sets)
      DescriptionSet.bulk_import(
        description_sets.uniq,
        on_duplicate_key_update: %i[envelope_resource_id uris]
      )
    end

    def maps
      @maps ||= YAML.load_file(
        MR.root_path.join('fixtures', 'description_set_item_maps.yml')
      )
    end
  end
end
