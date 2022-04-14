class CtdlSubclassesResolver
  CTDL_SUBCLASSES_MAP_FILE = MR.root_path.join("fixtures", "subclasses_map.json")

  attr_reader :root_class, :include_root

  def initialize(root_class:, include_root: true)
    @root_class = root_class
    @include_root = include_root
  end

  def subclasses
    @subclasses ||= collect_subclasses(initial_map_item) + (include_root ? [root_class] : [])
  end

  def initial_map_item
    ctdl_subclasses_map[root_class] || {}
  end

  def collect_subclasses(start)
    start.keys + start.values.flat_map do |i|
      collect_subclasses(i)
    end
  end

  def ctdl_subclasses_map
    @ctdl_subclasses_map ||= JSON.parse(File.read(CTDL_SUBCLASSES_MAP_FILE))
  end
end
