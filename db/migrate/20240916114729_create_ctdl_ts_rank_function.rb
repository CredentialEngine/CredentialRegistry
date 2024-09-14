class CreateCtdlTsRankFunction < ActiveRecord::Migration[7.1]
  def up
    ActiveRecord::Base.connection.execute(<<~COMMAND)
      CREATE OR REPLACE FUNCTION ctdl_ts_rank(search_term text, content text) RETURNS float AS $$
      DECLARE
        content_lower text;
        position_weight float;
        rank float := 0;
        search_term_lower text;
      BEGIN
        content_lower := lower(content);
        search_term_lower := lower(search_term);

        -- Check for exact match
        IF content_lower = search_term_lower THEN
          rank := rank + 1.0;
        END IF;

        -- Check for partial match and calculate position weight
        IF content_lower LIKE '%' || search_term_lower || '%' THEN
          position_weight := 1.0 - (position(search_term_lower in content_lower) - 1.0) / length(content_lower)::float;
          rank := rank + 0.5 * position_weight;
        END IF;

        -- Check if search term is a substring of content
        IF position(search_term_lower in content_lower) > 0 THEN
          position_weight := 1.0 - (position(search_term_lower in content_lower) - 1.0) / length(content_lower)::float;
          rank := rank + 0.3 * position_weight;
        END IF;

        -- Check if content is a substring of search term
        IF position(content_lower in search_term_lower) > 0 THEN
          rank := rank + 0.2;
        END IF;

        RETURN rank;
      END;
      $$ LANGUAGE plpgsql;
    COMMAND
  end

  def down
    ActiveRecord::Base.connection.execute('DROP FUNCTION ctdl_ts_rank')
  end
end
