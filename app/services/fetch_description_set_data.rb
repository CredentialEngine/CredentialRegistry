# Fetches description set data for the given CTIDs
class FetchDescriptionSetData
  def self.call(
    ctids,
    include_resources: false,
    path_contains: nil,
    path_exact: nil,
    per_branch_limit: nil
  )
    description_sets = DescriptionSet
      .where(ceterms_ctid: ctids)
      .select(:path)
      .select('cardinality(uris) total')

    if path_exact.present?
      description_sets.where!('LOWER(path) = ?', path_exact.downcase)
    elsif path_contains.present?
      description_sets.where!("path ILIKE '%#{path_contains}%'")
    end

    description_sets =
      if per_branch_limit
        description_sets.select("uris[1:#{per_branch_limit}] uris")
      else
        description_sets.select(:uris)
      end

    resources =
      if include_resources
        ids = description_sets.map(&:uris).flatten.uniq.map do |uri|
          id = uri.split('/').last
          next id unless uri.starts_with?('https://credreg.net/bnodes/')

          "_:#{id}"
        end

        EnvelopeResource.where(resource_id: ids).pluck(:processed_resource)
      end

    OpenStruct.new(
      description_sets: description_sets,
      resources: resources
    )
  end
end
