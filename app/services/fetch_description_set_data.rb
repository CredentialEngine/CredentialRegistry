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
      .select(:ceterms_ctid, :path)
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

        EnvelopeResource
          .not_deleted
          .where(resource_id: ids)
          .pluck(:processed_resource)
      end

   description_set_groups = description_sets
    .group_by(&:ceterms_ctid)
    .map do |group|
      OpenStruct.new(ctid: group.first, description_set: group.last)
    end

    OpenStruct.new(
      description_sets: description_set_groups,
      resources: resources
    )
  end
end
