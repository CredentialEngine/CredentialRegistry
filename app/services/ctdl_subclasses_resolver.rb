class CtdlSubclassesResolver # rubocop:todo Style/Documentation
  SUBCLASSES_MAP_FILE = MR.root_path.join('fixtures', 'subclasses_map.json')

  attr_accessor :root_class
  attr_reader :envelope_community_config, :include_root

  def initialize(envelope_community:, root_class: nil, include_root: true)
    @envelope_community_config = envelope_community.config
    @include_root = include_root
    @root_class = root_class
  end

  def all_classes(map = ctdl_subclasses_map)
    map.flat_map do |type, submap|
      [type, *all_classes(submap)]
    end.uniq
  end

  def subclasses
    @subclasses ||= collect_subclasses(initial_map_item) +
                    (include_root && root_class ? [root_class] : [])
  end

  def initial_map_item
    ctdl_subclasses_map[root_class] || {}
  end

  def collect_subclasses(start)
    start.keys + start.values.flat_map { collect_subclasses(it) }
  end

  def ctdl_subclasses_map
    @ctdl_subclasses_map ||= envelope_community_config.fetch(
      'subclasses_map',
      JSON.parse(File.read(SUBCLASSES_MAP_FILE))
    )
  end
end
