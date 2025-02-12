class CtdlSubclassesResolver # rubocop:todo Style/Documentation
  SUBCLASSES_MAP_FILE = MR.root_path.join('fixtures', 'subclasses_map.json')

  attr_reader :envelope_community_config, :include_root, :root_class

  def initialize(envelope_community:, root_class:, include_root: true)
    @envelope_community_config = envelope_community.config
    @include_root = include_root
    @root_class = root_class
  end

  def subclasses
    @subclasses ||= collect_subclasses(initial_map_item) +
                    (include_root ? [root_class] : [])
  end

  def initial_map_item
    ctdl_subclasses_map[root_class] || {}
  end

  def collect_subclasses(start)
    start.keys + start.values.flat_map { collect_subclasses(_1) }
  end

  def ctdl_subclasses_map
    @ctdl_subclasses_map ||= envelope_community_config.fetch(
      'subsclasses_map',
      JSON.parse(File.read(SUBCLASSES_MAP_FILE))
    )
  end
end
