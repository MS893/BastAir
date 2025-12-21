require 'test_helper'

class MarkdownServiceTest < ActiveSupport::TestCase
  def setup
    @markdown_service = MarkdownService.new
  end

  test "render converts markdown to html" do
    content = "**Texte en gras**"
    result = @markdown_service.render(content)
    
    # Vérifie que le markdown est bien interprété (gras -> strong)
    assert_match /<strong>Texte en gras<\/strong>/, result
  end

  test "render sanitizes script tags" do
    unsafe_content = "Bonjour <script>alert('XSS')</script> tout le monde"
    result = @markdown_service.render(unsafe_content)

    # Vérifie que la balise <script> a disparu
    assert_no_match /<script>/, result
    # Vérifie que le reste du texte est préservé
    assert_match /Bonjour/, result
  end
  
end