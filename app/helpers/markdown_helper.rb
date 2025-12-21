module MarkdownHelper

  def md(text)
    # On instancie le service et on appelle la méthode render
    @markdown_renderer ||= MarkdownService.new
    @markdown_renderer.render(text)
  end
  
end
