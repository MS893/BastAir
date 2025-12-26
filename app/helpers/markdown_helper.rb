# frozen_string_literal: true

module MarkdownHelper
  def md(text)
    markdown_renderer.render(text)
  end

  private

  # Mémoïse l'instance de MarkdownService pour éviter de créer un nouvel objet à chaque appel.
  def markdown_renderer
    @markdown_renderer ||= MarkdownService.new
  end
end
