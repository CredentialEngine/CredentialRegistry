# Encapsulates Markdown to HTML rendering
class RenderMarkdown
  include ERB::Util

  # project's root path
  @root_path = File.expand_path('../../../', __FILE__)

  # Get markdown content from file.
  # We read the file once and memoize it
  @content = Hash.new do |h, key|
    h[key] = File.read File.join(@root_path, "#{key}.md")
  end

  # class-instance variable accessors
  class << self; attr_reader :root_path, :content end

  attr_reader :filename

  def initialize(filename)
    @filename = filename
  end

  # render HTML from erb template
  def to_html
    @rendered ||= ERB.new(template).result(binding)
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
    Kramdown::Document.new(content, input: 'GFM').to_html
  end

  def title
    "#{filename} · Credential Registry"
  end

  private

  def path(fpath)
    File.join(self.class.root_path, fpath)
  end
end
