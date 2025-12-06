module Admin::TablesHelper
  # Retourne un tableau des colonnes à masquer pour une table donnée.
  def hidden_columns_for(table_name)
    base_hidden = %w[created_at updated_at]
    specific_hidden = case table_name
                      when 'attendances'
                        %w[stripe_customer_id]
                      when 'users'
                        %w[
                          date_naissance lieu_naissance profession adresse email encrypted_password
                          num_ffa num_licence date_licence type_medical medical nuit fi fe controle
                          cotisation_club cotisation_ffa google_access_token google_refresh_token
                          google_token_expires_at reset_password_token reset_password_sent_at
                          remember_created_at
                        ]
                      when 'avions'
                        %w[
                          marque modele conso_horaire certif_immat cert_navigabilite
                          cert_examen_navigabilite licence_station_aeronef cert_limitation_nuisances
                          fiche_pesee
                        ]
                      when 'reservations'
                        %w[
                          summary description location attendees google_event_id recurrence
                          reminders_data conference_data colorId source extended_properties
                          sharedExtendedProperties
                        ]
                      when 'tarifs'
                        %w[tarif_horaire_avion2]
                      when 'transactions'
                        %w[piece_justificative attachment_url]
                      when 'vols'
                        %w[
                          depart arrivee compteur_depart compteur_arrivee nature
                          fuel_avant_vol fuel_apres_vol huile
                        ]
                      else
                        []
                      end
    base_hidden + specific_hidden
  end

  # Génère le lien de tri pour les en-têtes de colonnes.
  def sortable_header(column, table_name, query_params)
    is_sorted_column = query_params[:sort_column] == column
    current_direction = query_params[:sort_direction]
    next_direction = is_sorted_column && current_direction == 'asc' ? 'desc' : 'asc'

    icon =  if is_sorted_column
              current_direction == 'asc' ? ' &#9650;'.html_safe : ' &#9660;'.html_safe
            end

    header_text = header_text_for(table_name, column)

    link_to(admin_tables_path(table_name: table_name, page: query_params[:page], query: query_params[:query], sort_column: column, sort_direction: next_direction),
            data: { turbo_frame: "table_content_frame", turbo_action: "advance" }) do
      "#{header_text}#{icon}".html_safe
    end
  end

  # Formate le contenu d'une cellule en fonction de la colonne et de la table.
  def display_cell_content(record, column, table_name)
    value = record.public_send(column)

    # Cas spécial pour l'immatriculation des avions pour éviter la césure
    if table_name == 'avions' && column == 'immatriculation'
      return content_tag(:span, value, style: 'white-space: nowrap;')
    end

    # Cas spécial pour le champ 'fi' de la table 'reservations' qui contient un ID d'instructeur
    if table_name == 'reservations' && column == 'fi' && value.present?
      instructeur = @users_by_id[value.to_i]
      return instructeur ? "#{instructeur.prenom} #{instructeur.nom}" : "ID: #{value}"
    end

    # Gestion des clés étrangères
    if column.end_with?('_id')
      return display_association_name(record, column, table_name, value) || "ID: #{value}"
    end

    # Gestion des types de données spécifiques
    case @model.column_for_attribute(column).type
    when :boolean
      value ? content_tag(:span, 'Oui', class: 'badge bg-success') : content_tag(:span, 'Non', class: 'badge bg-danger')
    when :datetime, :timestamp
      value&.strftime('%d/%m/%y %H:%M UTC')
    when :date
      value&.strftime('%d/%m/%y')
    else
      truncate(value.to_s, length: 70)
    end
  end

  # Formate un attribut pour l'affichage dans la page de détail d'un enregistrement.
  def display_record_attribute(record, attr_name, associated_records)
    value = record.public_send(attr_name)

    # Cas spécial pour le champ 'fi' de la table 'reservations' qui contient un ID d'instructeur
    if record.class.table_name == 'reservations' && attr_name == 'fi' && value.present?
      instructor = User.find_by(id: value.to_i)
      return instructor ? "#{instructor.prenom} #{instructor.nom}" : "Instructeur ID: #{value}"
    end

    if associated_records.key?(attr_name) && (associated_record = associated_records[attr_name])
      # Clé étrangère avec enregistrement associé chargé
      if associated_record.is_a?(User)
        "#{associated_record.prenom} #{associated_record.nom}"
      else
        associated_record.try(:name) || associated_record.try(:title) || "Enregistrement ##{value}"
      end
    elsif attr_name.end_with?('_id')
      value.present? ? "ID: #{value}" : 'N/A'
    elsif value.is_a?(TrueClass) || value.is_a?(FalseClass)
      # Affichage des booléens
      value ? content_tag(:span, 'Oui', class: 'badge bg-success') : content_tag(:span, 'Non', class: 'badge bg-danger')
    elsif value.is_a?(Date) || value.is_a?(Time)
      # Formatage des dates et heures
      l(value, format: :long)
    else
      # Valeur par défaut, avec gestion des valeurs vides
      value.presence || content_tag(:em, 'N/A', class: 'text-muted')
    end
  end

  private

  # Retourne le texte personnalisé pour un en-tête de colonne.
  def header_text_for(table_name, column_name)
    case [table_name, column_name]
    when ['avions', 'immatriculation']
      'Immat'
    when ['vols', 'nb_atterro']
      'Nb att'
    else
      column_name.humanize
    end
  end

  # Affiche le nom d'un enregistrement associé.
  def display_association_name(record, column, table_name, value)
    return unless value

    case column
    when 'user_id', 'admin_id', 'instructeur_id'
      user = @users_by_id[value]
      user ? "#{user.prenom} #{user.nom}" : nil
    when 'event_id'
      event = @events_by_id[value]
      event ? event.title : nil
    when 'avion_id'
      avion = @avions_by_id[value]
      avion ? content_tag(:span, avion.immatriculation, style: 'white-space: nowrap;') : nil
    end
  end
end
