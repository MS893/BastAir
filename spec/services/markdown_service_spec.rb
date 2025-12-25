# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarkdownService do
  subject { described_class.new }

  describe '#render' do
    it 'converts markdown to html' do
      content = '**Texte en gras**'
      result = subject.render(content)

      # Vérifie que le markdown est bien interprété (gras -> strong)
      expect(result).to match(%r{<strong>Texte en gras</strong>})
    end

    it 'sanitizes script tags' do
      unsafe_content = "Bonjour <script>alert('XSS')</script> tout le monde"
      result = subject.render(unsafe_content)

      # Vérifie que la balise <script> a disparu
      expect(result).not_to match(/<script>/)
      # Vérifie que le reste du texte est préservé
      expect(result).to match(/Bonjour/)
    end
  end
end
