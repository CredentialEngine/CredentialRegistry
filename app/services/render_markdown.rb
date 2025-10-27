# Encapsulates Markdown to HTML rendering
class RenderMarkdown
  include ERB::Util

  # project's root path
  @root_path = File.expand_path('../..', __dir__)

  # Restrict renderable markdown files to a fixed allowlist to avoid
  # accidental path traversal or rendering of unexpected files.
  NAME_PATTERN = /\A[A-Za-z0-9_-]+\z/

  # Directory containing markdown content (e.g., docs/*.md) and optional README.md
  CONTENT_DIR = File.join(@root_path, 'docs')

  # Build a name=>absolute_path map for allowed markdown files
  @allowed_paths = begin
    paths = {}
    # docs/*.md files
    Dir[File.join(CONTENT_DIR, '*.md')].each do |p|
      name = File.basename(p, '.md')
      paths[name] = p
    end
    # Optionally allow README.md at repo root
    readme = File.join(@root_path, 'README.md')
    paths['README'] = readme if File.file?(readme)
    paths.freeze
  end

  class << self
    attr_reader :allowed_paths
  end

  # Get markdown content from file.
  # We read the file once and memoize it
  @content = Hash.new do |h, key|
    path = allowed_paths[key]
    raise ArgumentError, 'Unknown page' unless path

    h[key] = File.read(path)
  end

  # class-instance variable accessors
  class << self; attr_reader :root_path, :content end

  attr_reader :filename

  def initialize(filename)
    fname = filename.to_s
    raise ArgumentError, 'Invalid page name' unless NAME_PATTERN.match?(fname)
    raise ArgumentError, 'Unknown page' unless self.class.allowed_paths.key?(fname)

    @filename = fname
  end

  # render HTML from erb template
  def to_html
    @to_html ||= ERB.new(template).result(binding)
  end

  # load template from file
  # Return: [String]
  def template
    @template ||= File.read path('app/views/page.html.erb')
  end

  # Render body content to HTML
  # Return: [String] parsed HTML
  def body
    content = self.class.content[filename]
    # Disable raw HTML in markdown to prevent script injection via content files
    Kramdown::Document.new(
      content,
      input: 'GFM',
      parse_block_html: false,
      parse_span_html: false
    ).to_html
  end

  def title
    "#{h filename} · Credential Registry"
  end

  private

  def path(fpath)
    File.join(self.class.root_path, fpath)
  end
end
