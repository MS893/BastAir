# Fichier: config/initializers/redcarpet_markdown.rb

# 1. Définition du moteur de rendu (optionnel mais recommandé)
class CustomHtmlRenderer < Redcarpet::Render::HTML
  # Vous pouvez ajouter ici des méthodes pour personnaliser le rendu
end

# 2. Définition des options de rendu (pour l'affichage)
renderer_options = {
  # Pour la couleur : permet au HTML brut (comme le span style) de passer.
  unsafe: true,

  # Pour l'aération : transforme les sauts de ligne simples en <br> HTML.
  hard_wrap: true,

  # Désactive le filtre HTML par défaut de Redcarpet (moins strict)
  filter_html: false
}

# 3. Définition des extensions Markdown (pour le formatage)
markdown_extensions = {
  no_intra_emphasis: true, # Ne reconnaît pas le gras/italique à l'intérieur des mots
  fenced_code_blocks: true, # Support des blocs de code avec triple accent grave (```)
  autolink: true,          # Transforme les URL en liens
  tables: true,            # Supporte le formatage des tableaux
  with_toc_data: true,     # Ajoute des ID aux titres pour les ancres
  disable_indented_code_blocks: true # Préfère les blocs de code 'fenced'
}

# 4. Création de l'objet de rendu final
MARKDOWN_RENDERER = Redcarpet::Markdown.new(
  CustomHtmlRenderer.new(renderer_options),
  markdown_extensions
)
