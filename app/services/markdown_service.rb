# app/services/markdown_service.rb
class MarkdownService
  def initialize
    @renderer = Redcarpet::Render::HTML.new(hard_wrap: true, filter_html: true)
    @markdown = Redcarpet::Markdown.new(@renderer, extensions = {
      autolink: true,
      tables: true,
      fenced_code_blocks: true
    })
  end

  def render(text)
    @markdown.render(text).html_safe
  end
end