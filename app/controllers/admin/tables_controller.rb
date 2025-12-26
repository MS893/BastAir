# frozen_string_literal: true

# app/controllers/admin/tables_controller.rb
require 'kaminari'

module Admin
  class TablesController < ApplicationController
    before_action :authorize_admin!
    helper_method :current_model, :users_by_id, :avions_by_id, :events_by_id

    # Centralise la configuration des associations à précharger pour chaque table.
    # Clé: nom de la table.
    # Valeur: un hash où la clé est le type d'ID (ex: :user_ids) et la valeur est la ou les colonnes correspondantes.
    ASSOCIATIONS_TO_PRELOAD = {
      'activity_logs' => { user_ids: :user_id },
      'attendances' => { user_ids: :user_id, event_ids: :event_id },
      'comments' => { user_ids: :user_id, event_ids: :event_id },
      'events' => { user_ids: :admin_id }, # admin_id est un user_id
      'instructor_availabilities' => { user_ids: :user_id },
      'news_items' => { user_ids: :user_id },
      'reservations' => { user_ids: :user_id, avion_ids: :avion_id },
      'signalements' => { user_ids: :user_id, avion_ids: :avion_id },
      'transactions' => { user_ids: :user_id },
      'immobs' => { transaction_ids: :purchase_transaction_id },
      'vols' => { user_ids: %i[user_id instructeur_id], avion_ids: :avion_id }
    }.freeze

    def index
      excluded_tables = [
        'ar_internal_metadata',
        'schema_migrations',
        'active_storage_attachments',
        'active_storage_blobs',
        'active_storage_variant_records',
        'web_push_subscriptions',
        'questions' # Table interne de gestion des QCM, non pertinente pour l'admin
        # 'livrets' # à rajouter livrets de progression plus tard
      ]

      # On définit manuellement l'ordre des tables pour un contrôle total.
      ordered_tables = [
        'activity_logs',                # Historique d'activité
        'users',                        # Adhérents
        'avions',                       # Avions
        'comments',                     # Commentaires
        'instructor_availabilities',    # Disponibilités FI
        'transactions',                 # Comptabilité
        'news_items',                   # Consignes
        'courses',                      # Cours
        'events',                       # Evènements
        'immobs',                       # Immobilisations
        'flight_lessons',               # Instruction
        'mels',                         # MEL
        'settings',                     # Paramètres
        'attendances',                  # Participants
        'penalites',                    # Pénalités
        'audios',                       # Podcasts
        'reservations',                 # Réservations
        'signalements',                 # Signalements
        'tarifs',                       # Tarifs
        'vols'                          # Vols
      ]

      # On s'assure que seules les tables existantes sont affichées, tout en conservant l'ordre défini.
      all_existing_tables = ActiveRecord::Base.connection.tables - excluded_tables
      @tables = all_existing_tables.sort_by do |table_name|
        ordered_tables.index(table_name) || Float::INFINITY
      end

      return unless params[:table_name].present? && @tables.include?(params[:table_name])

      @selected_table = params[:table_name]
      @model = create_anonymous_model(params[:table_name])

      # 1. Construire la requête de base avec filtres et tri (sans l'exécuter)
      filtered_records =  if @selected_table == 'transactions'
                            Transaction.unscoped # Inclut les transactions "discarded"
                          else
                            @model.all
                          end

      if params[:query].present?
        query_term = "%#{params[:query].downcase}%"
        conditions = @model.column_names.map do |col|
          "LOWER(CAST(#{col} AS TEXT)) LIKE :query"
        end.join(' OR ')
        filtered_records = filtered_records.where(conditions, query: query_term)
      end

      # Filtre par type d'action (spécifique pour activity_logs ou tables avec colonne 'action')
      filtered_records = filtered_records.where(action: params[:action_type]) if params[:action_type].present? && @model.column_names.include?('action')

      # Filtre par type d'enregistrement (spécifique pour activity_logs)
      filtered_records = filtered_records.where(record_type: params[:record_type]) if params[:record_type].present? && @model.column_names.include?('record_type')

      if params[:sort_column].present? && @model.column_names.include?(params[:sort_column])
        sort_direction = %w[asc desc].include?(params[:sort_direction]) ? params[:sort_direction] : 'asc'
        filtered_records = filtered_records.order("#{params[:sort_column]} #{sort_direction}")
      end

      # 2. Précharger les données associées en utilisant la requête filtrée (avant pagination)
      preload_associations(filtered_records)

      # Récupère les actions distinctes pour le filtre (uniquement pour activity_logs)
      if @selected_table == 'activity_logs'
        @available_actions = @model.distinct.pluck(:action).compact.sort
        @available_record_types = @model.distinct.pluck(:record_type).compact.sort
      end

      # 3. Paginer les résultats pour l'affichage
      @records = filtered_records.page(params[:page]).per(10)

      respond_to do |format|
        format.html # pour le chargement initial de la page
        # Pour les mises à jour via Turbo, on s'assure de re-rendre la liste des tables et le contenu de la table sélectionnée.
        # Le rendu se fait via la vue `index.turbo_stream.erb` qui est implicitement appelée.
        # Nous nous assurons que les variables d'instance sont correctement définies pour cette vue.
        format.turbo_stream
      end
    end

    def show_record
      @table_name = params[:table_name]
      @model = create_anonymous_model(@table_name)
      @record = if @table_name == 'transactions'
                  Transaction.unscoped.find(params[:id]) # Permet de trouver les transactions même si elles sont supprimées logiquement
                else
                  @model.find(params[:id])
                end
      @associated_records = {}

      # Détecte les clés étrangères et charge les enregistrements associés.
      @model.columns.each do |column|
        next unless column.name.end_with?('_id') && column.name != 'id'

        associated_model_name = if column.name == 'admin_id'
                                  'User'
                                else
                                  column.name.chomp('_id').classify
                                end
        associated_model_name = 'Transaction' if column.name == 'purchase_transaction_id'
        begin
          associated_model_class = associated_model_name.constantize
          if associated_model_class < ActiveRecord::Base
            record_id = @record.send(column.name)
            @associated_records[column.name] = associated_model_class.find_by(id: record_id) if record_id.present?
          end
        rescue NameError
          next # Ignore si le modèle déduit n'existe pas.
        end
      end
    end

    def edit_record
      @table_name = params[:table_name]
      @model = create_anonymous_model(@table_name)
      @record = @model.find(params[:id])
      @type_vols = ['Vol découverte', "Vol d'initiation", "Vol d'essai", 'Convoyage', 'Vol BIA'] # Maintenu pour 'reservations' et 'vols'

      # Prépare la liste des instructeurs pour le formulaire d'édition des réservations.
      # Un instructeur est un utilisateur avec une date de qualification FI valide.
      case @table_name
      when 'reservations'
        @instructors_for_select = User.where('fi IS NOT NULL AND fi >= ?', Time.zone.today).order(:nom, :prenom).map do |u|
          ["#{u.prenom} #{u.nom}", u.id]
        end
        @google_calendar_colors = {
          '1' => 'Lavande',
          '2' => 'Sauge',
          '3' => 'Mauve',
          '4' => 'Rose',
          '5' => 'Jaune',
          '6' => 'Orange',
          '7' => 'Cyan',
          '8' => 'Gris',
          '9' => 'Bleu',
          '10' => 'Vert',
          '11' => 'Rouge'
        }.invert.to_a # On inverse pour avoir [Nom, ID]
        @reservation_visibilities = %w[public private]
        @reservation_statuses = %w[confirmed tentative cancelled]
        @reservation_time_zones = Setting::ALLOWED_TIME_ZONES
      when 'signalements'
        # Prépare la liste des statuts pour le formulaire d'édition des signalements.
        @signalement_statuses = ['Ouvert', 'En cours', 'Résolu']
      when 'users'
        # Prépare la liste des fonctions pour le formulaire d'édition des utilisateurs.
        @user_fonctions = User::ALLOWED_FCT.values
        @user_medical_types = User::ALLOWED_MED.values
        @user_licence_types = User::ALLOWED_LIC.values
      when 'events'
        @event_titles = Event::ALLOWED_TITLES
      when 'vols'
        @instructors_for_select = User.where('fi IS NOT NULL AND fi >= ?', Time.zone.today).order(:nom, :prenom).map do |u|
          ["#{u.prenom} #{u.nom}", u.id]
        end
        @nature_vols = ['VFR de jour', 'VFR de nuit', 'IFR']
      when 'tarifs'
        current_year = Date.current.year
        @tarif_annee_options = (current_year..(current_year + 2)).to_a
      end
      set_foreign_key_options
    end

    def new_record
      @table_name = params[:table_name]
      @model = create_anonymous_model(@table_name)

      # On pré-remplit le formulaire avec les paramètres passés dans l'URL, si présents.
      # C'est utile pour créer une immobilisation depuis une transaction.
      allowed_initial_params = @model.column_names.map(&:to_sym)
      @record = @model.new(params.permit(allowed_initial_params))

      # --- Préparation des données spécifiques pour le formulaire de création ---
      if @table_name == 'tarifs'
        # On cherche le tarif le plus récent pour pré-remplir les champs
        latest_tarif = Tarif.order(annee: :desc).first
        if latest_tarif
          # On initialise le nouvel enregistrement avec les attributs de l'ancien
          @record = @model.new(latest_tarif.attributes.except('id', 'created_at', 'updated_at'))
          # On incrémente l'année
          @record.annee = latest_tarif.annee + 1
        else
          # Comportement par défaut si aucun tarif n'existe
          @record.annee = Date.current.year
        end
        @tarif_annee_options = ((@record.annee - 1)..(@record.annee + 2)).to_a
      end

      # Prépare les options pour toutes les clés étrangères (ex: avion_id pour un vol)
      set_foreign_key_options

      # On réutilise la vue d'édition pour le formulaire de création
      render :edit_record
    end

    def update_record
      @table_name = params[:table_name]
      @model = create_anonymous_model(@table_name)
      @record = @model.find(params[:id])

      set_foreign_key_options # Pour que le formulaire puisse être re-rendu correctement en cas d'erreur
      process_reservation_datetime_params if @table_name == 'reservations'

      if @record.update(record_params)
        if @table_name == 'transactions'
          # Enregistre la modification de la transaction et crée une entrée dans les ActivityLogs
          ActivityLog.create(
            user: current_user,
            action: 'update',
            record_type: 'transactions',
            record_id: @record.id,
            details: "Modification de la transaction (Admin) : #{@record.description} (#{@record.montant} €)"
          )
        end
        redirect_to admin_tables_path(table_name: @table_name), notice: "L'enregistrement a été mis à jour avec succès."
      else
        render :edit_record, status: :unprocessable_content
      end
    end

    def create_record
      @table_name = params[:table_name]
      @model = create_anonymous_model(@table_name)
      @record = @model.new(record_params)

      process_reservation_datetime_params if @table_name == 'reservations'

      if @record.save
        if @table_name == 'transactions'
          # Enregistre la création de la transaction et crée une entrée dans les ActivityLogs
          ActivityLog.create(
            user: current_user,
            action: 'create',
            record_type: 'transactions',
            record_id: @record.id,
            details: "Création de la transaction (Admin) : #{@record.description} (#{@record.montant} €)"
          )
        end
        redirect_to admin_tables_path(table_name: @table_name), notice: "L'enregistrement a été créé avec succès."
      else
        # Si la sauvegarde échoue, on ne recrée pas un nouvel objet.
        # On prépare les données nécessaires pour le formulaire (clés étrangères, etc.)
        # et on ré-affiche le formulaire d'édition avec l'objet @record actuel, qui contient les erreurs.
        set_foreign_key_options

        render :edit_record, status: :unprocessable_content
      end
    end

    def destroy_record
      @table_name = params[:table_name]
      @model = create_anonymous_model(@table_name)
      notice_message = "L'enregistrement a été supprimé avec succès."

      if @table_name == 'transactions'
        @record = Transaction.unscoped.find(params[:id]) # On doit pouvoir trouver la transaction même si elle est déjà "supprimée"
        if params[:force] == 'true'
          action_type = 'delete'
          log_details = "Suppression DÉFINITIVE de la transaction: #{@record.description} d'un montant de #{@record.montant} €"
          @record.destroy! # Suppression physique forcée
          notice_message = 'La transaction a été supprimée définitivement.'
        else
          action_type = 'discard'
          log_details = "Mise à la corbeille de la transaction: #{@record.description} d'un montant de #{@record.montant} €"
          @record.discard # Marque la transaction comme supprimée logiquement
          notice_message = 'La transaction a été mise à la corbeille.'
        end
      else
        @record = @model.find(params[:id])
        action_type = 'delete'
        log_details = "Suppression de l'enregistrement: #{@record.id} de la table #{@table_name}"
        @record.destroy # Suppression physique pour les autres tables
      end

      # --- Journalisation de l'action de suppression ---
      if @table_name == 'transactions' # Log uniquement pour les transactions
        ActivityLog.create!(
          user: current_user,
          action: action_type,
          record_type: @table_name,
          record_id: @record.id,
          details: log_details
        )
      end

      redirect_to admin_tables_path(table_name: @table_name), notice: notice_message, status: :see_other
    end

    def restore_record
      @table_name = params[:table_name]
      @record = Transaction.unscoped.find(params[:id]) # On doit pouvoir trouver la transaction même si elle est "supprimée"
      @record.restore # Restaure la transaction

      ActivityLog.create!(
        user: current_user,
        action: 'restore',
        record_type: @table_name,
        record_id: @record.id,
        details: "Restauration de la transaction: #{@record.description} d'un montant de #{@record.montant} €"
      )

      redirect_to admin_tables_path(table_name: @table_name), notice: 'La transaction a été restaurée avec succès.',
                                                              status: :see_other
    end

    private

    def current_model
      @model
    end

    def users_by_id
      @users_by_id || {}
    end

    def avions_by_id
      @avions_by_id || {}
    end

    def events_by_id
      @events_by_id || {}
    end

    def preload_associations(records)
      @users_by_id = {}
      @avions_by_id = {}
      @events_by_id = {}
      @transactions_by_id = {}

      config = ASSOCIATIONS_TO_PRELOAD[@selected_table]
      return unless config

      ids_to_fetch = { user_ids: [], avion_ids: [], event_ids: [], transaction_ids: [] }

      config.each do |id_group, columns|
        # `columns` peut être un symbole unique ou un tableau de symboles
        Array(columns).each do |column|
          # Utilise `pluck` sur la relation `records` (qui est filtrée mais pas encore paginée)
          # pour récupérer tous les IDs pertinents.
          ids_to_fetch[id_group] += records.pluck(column)
        end
      end

      # Charge les enregistrements associés en une seule requête par modèle
      @users_by_id = User.where(id: ids_to_fetch[:user_ids].compact.uniq).index_by(&:id) if ids_to_fetch[:user_ids].present?
      @avions_by_id = Avion.where(id: ids_to_fetch[:avion_ids].compact.uniq).index_by(&:id) if ids_to_fetch[:avion_ids].present?
      @events_by_id = Event.where(id: ids_to_fetch[:event_ids].compact.uniq).index_by(&:id) if ids_to_fetch[:event_ids].present?
      return if ids_to_fetch[:transaction_ids].blank?

      @transactions_by_id = Transaction.where(id: ids_to_fetch[:transaction_ids].compact.uniq).index_by(&:id)
    end

    def translate_table_name(table_name)
      translations = {
        'activity_logs' => 'Historique d\'activité',
        'attendances' => 'Participants',
        'audios' => 'Podcasts',
        'avions' => 'Avions',
        'instructor_availabilities' => 'Disponibilités FI',
        'comments' => 'Commentaires',
        'courses' => 'Cours',
        'events' => 'Evènements',
        'flight_lessons' => 'Instruction',
        'news_items' => 'Consignes',
        'immobs' => 'Immobilisations',
        'reservations' => 'Réservations',
        'signalements' => 'Signalements',
        'tarifs' => 'Tarifs',
        'transactions' => 'Comptabilité',
        'users' => 'Adhérents',
        'penalites' => 'Pénalités',
        'settings' => 'Paramètres',
        'mels' => 'MEL',
        'vols' => 'Vols'
      }
      translations.fetch(table_name, table_name.humanize)
    end

    helper_method :translate_table_name

    def create_anonymous_model(table_name)
      # Crée une classe anonyme pour interagir avec n'importe quelle table.
      # La partie `model_name` est cruciale pour que les helpers de formulaire (form_with)
      # fonctionnent correctement avec un objet issu d'une classe anonyme.
      Class.new(ApplicationRecord) do
        self.table_name = table_name
        def self.model_name = ActiveModel::Name.new(self, nil, 'Record')
        # On ajoute des accesseurs pour nos champs virtuels si c'est une réservation
        if table_name == 'reservations'
          attr_accessor :start_date, :start_hour, :start_minute, :end_date, :end_hour,
                        :end_minute
        end

        # Ajout de validations spécifiques à la table
        if table_name == 'tarifs'
          validates :annee,
                    uniqueness: { scope: :avion_id, message: 'Un tarif existe déjà pour cet avion et cette année.' }
          validates :avion_id, presence: { message: 'Veuillez sélectionner un avion.' }
          validates :tarif_horaire_avion1, presence: { message: "Le tarif horaire de l'avion est obligatoire." }
          validates :tarif_instructeur, presence: { message: 'Le tarif instructeur est obligatoire.' }
        end

        # Ajoute dynamiquement des validations basées sur les propriétés des colonnes
        columns.each do |column|
          # Exclut les colonnes 'id', 'created_at', 'updated_at' des validations automatiques
          next if %w[id created_at updated_at].include?(column.name)

          # Validation de présence pour les colonnes NOT NULL
          unless column.null
            if column.type == :boolean
              validates_inclusion_of column.name, in: [true, false]
            else
              validates_presence_of column.name
            end
          end

          # Validation de numericalité pour les types numériques
          # allow_blank: true est utilisé pour éviter des erreurs en double si validates_presence_of est déjà appliqué
          validates_numericality_of column.name, allow_blank: true if %i[integer float decimal].include?(column.type)

          # Validation de longueur pour les colonnes string/text avec une limite définie
          validates_length_of column.name, maximum: column.limit, allow_blank: true if %i[string text].include?(column.type) && column.limit.present? && column.limit.positive?
        end
      end
    end

    def set_foreign_key_options
      @foreign_key_options = {}
      @model.columns.each do |column|
        # Vérifie si c'est une clé étrangère (se termine par _id, mais n'est pas 'id' lui-même)
        next unless column.name.end_with?('_id') && column.name != 'id'

        # Déduit le nom du modèle associé (ex: 'user_id' -> 'User')
        associated_model_name = if column.name == 'admin_id'
                                  'User'
                                else
                                  column.name.chomp('_id').classify
                                end
        begin
          associated_model_class = associated_model_name.constantize
          # S'assure que c'est bien un modèle ActiveRecord
          if associated_model_class < ActiveRecord::Base
            # Détermine un attribut ou une méthode d'affichage approprié pour la liste déroulante
            if column.name == 'admin_id'
              # Cas spécial pour admin_id (table events) : ne lister que les admins
              @foreign_key_options[column.name] = User.where(admin: true).order(:nom, :prenom).map do |record|
                ["#{record.prenom} #{record.nom}", record.id]
              end
            elsif %w[comments attendances news_items signalements
                     transactions].include?(@table_name) && column.name == 'user_id'
              # Cas spécial pour user_id (tables comments, attendances, news_items, signalements, transactions) : ne lister que les admins
              @foreign_key_options[column.name] = { options: User.where(admin: true).order(:nom, :prenom).map do |record|
                ["#{record.prenom} #{record.nom}", record.id]
              end, selected: @record.user_id }
            elsif associated_model_class.column_names.include?('prenom') && associated_model_class.column_names.include?('nom')
              # Cas spécial pour les modèles avec prénom et nom (comme User)
              @foreign_key_options[column.name] = associated_model_class.all.map do |record|
                ["#{record.prenom} #{record.nom}", record.id]
              end
            elsif associated_model_class.column_names.include?('immatriculation')
              # Cas spécial pour les modèles avec une immatriculation (comme Avion)
              @foreign_key_options[column.name] = associated_model_class.order(:immatriculation).map do |record|
                [record.immatriculation, record.id]
              end
            elsif associated_model_class.column_names.include?('title')
              # Cas spécial pour les modèles avec un titre (comme Event), en s'assurant de l'unicité du titre.
              options = associated_model_class.select('MIN(id) as id, title').group(:title).order(:title).map do |r|
                [r.title, r.id]
              end
              current_value = @record.send(column.name)
              # S'assure que l'ID actuel est dans la liste, même si ce n'est pas le MIN(id)
              unless options.any? { |opt| opt[1] == current_value }
                current_event = associated_model_class.find_by(id: current_value)
                options << [current_event.title, current_event.id] if current_event
              end
              @foreign_key_options[column.name] = options
            elsif column.name == 'purchase_transaction_id' # This is correct for set_foreign_key_options
              # Cas spécial pour la transaction d'achat d'une immobilisation.
              # Si l'ID est déjà présent (pré-rempli), on ne génère pas la liste déroulante.
              # Le formulaire utilisera un champ caché à la place.
              next if @record.purchase_transaction_id.present?

              @foreign_key_options[column.name] = associated_model_class.order(date_transaction: :desc).map do |record|
                ["#{l(record.date_transaction, format: :short)} - #{record.description.truncate(50)}", record.id]
              end
            else
              display_attribute = if associated_model_class.column_names.include?('name')
                                    'name'
                                  elsif associated_model_class.column_names.include?('title')
                                    'title'
                                  elsif associated_model_class.column_names.include?('email')
                                    'email'
                                  else
                                    'id' # Retourne à l'ID si aucun attribut d'affichage commun
                                  end
              # Récupère tous les enregistrements du modèle associé et les formate pour options_for_select
              @foreign_key_options[column.name] = associated_model_class.all.map do |record|
                [record.send(display_attribute).to_s, record.id]
              end
            end
          end
        rescue NameError # Si le modèle déduit n'existe pas, le traite comme un champ entier normal
          next
        end
      end
    end

    # Gère la combinaison des champs de date et d'heure pour les réservations
    def process_reservation_datetime_params
      # La logique est maintenant dans record_params pour s'assurer que les validations du modèle passent.
    end

    def record_params
      record_params = params.require(:record)

      if @table_name == 'reservations'
        # On combine les champs séparés en vrais champs datetime AVANT la validation.
        if record_params[:start_date].present? && record_params[:start_hour].present? && record_params[:start_minute].present?
          record_params[:start_time] =
            Time.zone.parse("#{record_params[:start_date]} #{record_params[:start_hour]}:#{record_params[:start_minute]}")
        end
        if record_params[:end_date].present? && record_params[:end_hour].present? && record_params[:end_minute].present?
          record_params[:end_time] =
            Time.zone.parse("#{record_params[:end_date]} #{record_params[:end_hour]}:#{record_params[:end_minute]}")
        end
      end

      excluded_params = %w[id created_at updated_at]

      permitted_params = @model.column_names - excluded_params # Autorise les vrais champs du modèle
      if @table_name == 'reservations'
        # On autorise explicitement les champs virtuels du formulaire pour qu'ils ne soient pas filtrés
        permitted_params += %w[start_date start_hour start_minute end_date end_hour end_minute]
      end
      record_params.permit(permitted_params.uniq)
    end
  end
end
