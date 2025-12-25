# frozen_string_literal: true

# app/services/markdown_service.rb
require 'commonmarker'
# On inclut le helper de Rails pour pouvoir utiliser `sanitize`
include ActionView::Helpers::SanitizeHelper

class MarkdownService
  def initialize
    # Syntaxe obligatoire pour Commonmarker 2.x
    @options = {
      render: {
        hardbreaks: true,  # Force le <br> sur un simple retour à la ligne
        unsafe: true       # Autorise le HTML brut (souvent nécessaire)
      },
      extension: {
        autolink: true,
        table: true,
        strikethrough: true,
        tasklist: true
      }
    }
  end

  def render(text)
    return '' if text.blank?

    # 1. On convertit le Markdown en HTML. L'option `unsafe: true` est un risque.
    unsafe_html = Commonmarker.to_html(text, options: @options)

    # 2. On nettoie le HTML pour enlever les balises dangereuses (ex: <script>)
    #    Le résultat de sanitize() est déjà considéré comme "html_safe".
    #    On autorise les balises de tableaux et l'attribut 'align' pour le formatage.
    allowed_tags = %w[h1 h2 h3 h4 h5 h6 p br b i strong em ul ol li a img blockquote pre code table thead tbody tfoot
                      tr th td hr span div del input]
    allowed_attributes = %w[href src alt title align class style target id name type checked disabled]
    sanitize(unsafe_html, tags: allowed_tags, attributes: allowed_attributes)
  end
end
