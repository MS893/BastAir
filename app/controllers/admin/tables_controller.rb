# app/controllers/admin/tables_controller.rb
require  'kaminari'

module Admin
  class TablesController < ApplicationController
    before_action :authorize_admin!

    def index
      excluded_tables = [
        'ar_internal_metadata',
        'schema_migrations',
        'active_storage_attachments',
        'active_storage_blobs',
        'active_storage_variant_records',
        'web_push_subscriptions'
      ]
      @tables = (ActiveRecord::Base.connection.tables - excluded_tables).sort
      if params[:table_name].present? && @tables.include?(params[:table_name])
        @selected_table = params[:table_name]
        @model = create_anonymous_model(params[:table_name])
        @records = @model.all

        if params[:query].present?
          query_term = "%#{params[:query].downcase}%"
          # On construit une requête qui cherche dans toutes les colonnes de la table
          # en les castant en texte pour une recherche universelle.
          conditions = @model.column_names.map do |col|
            "LOWER(CAST(#{col} AS TEXT)) LIKE :query"
          end.join(' OR ')
          @records = @records.where(conditions, query: query_term)
        end

        if params[:sort_column].present? && @model.column_names.include?(params[:sort_column])
          sort_direction = %w[asc desc].include?(params[:sort_direction]) ? params[:sort_direction] : 'asc'
          @records = @records.order("#{params[:sort_column]} #{sort_direction}")
        end

        @records = @records.page(params[:page]).per(10)

        # Initialise les hashes d'associations avant de charger les données
        @users_by_id = {}
        @avions_by_id = {}
        @events_by_id = {}
  
        # Détermine quels IDs charger selon la table
        if @selected_table == 'attendances'
          # Charger TOUS les user_id et event_id avant pagination
          all_records = @model.all
          if params[:query].present?
            query_term = "%#{params[:query].downcase}%"
            conditions = @model.column_names.map { |col| "LOWER(CAST(#{col} AS TEXT)) LIKE :query" }.join(' OR ')
            all_records = all_records.where(conditions, query: query_term)
          end
          if params[:sort_column].present? && @model.column_names.include?(params[:sort_column])
            sort_direction = %w[asc desc].include?(params[:sort_direction]) ? params[:sort_direction] : 'asc'
            all_records = all_records.order("#{params[:sort_column]} #{sort_direction}")
          end
          user_ids = all_records.pluck(:user_id).uniq
          event_ids = all_records.pluck(:event_id).uniq
          @users_by_id = User.where(id: user_ids).index_by(&:id)
          @events_by_id = Event.where(id: event_ids).index_by(&:id)
        elsif @selected_table == 'comments'
          # Charger TOUS les user_id et event_id avant pagination
          all_records = @model.all
          if params[:query].present?
            query_term = "%#{params[:query].downcase}%"
            conditions = @model.column_names.map { |col| "LOWER(CAST(#{col} AS TEXT)) LIKE :query" }.join(' OR ')
            all_records = all_records.where(conditions, query: query_term)
          end
          if params[:sort_column].present? && @model.column_names.include?(params[:sort_column])
            sort_direction = %w[asc desc].include?(params[:sort_direction]) ? params[:sort_direction] : 'asc'
            all_records = all_records.order("#{params[:sort_column]} #{sort_direction}")
          end
          user_ids = all_records.pluck(:user_id).uniq
          event_ids = all_records.pluck(:event_id).uniq
          @users_by_id = User.where(id: user_ids).index_by(&:id)
          @events_by_id = Event.where(id: event_ids).index_by(&:id)
        elsif @selected_table == 'events'
          # Charger TOUS les admin_id avant pagination
          all_records = @model.all
          if params[:query].present?
            query_term = "%#{params[:query].downcase}%"
            conditions = @model.column_names.map { |col| "LOWER(CAST(#{col} AS TEXT)) LIKE :query" }.join(' OR ')
            all_records = all_records.where(conditions, query: query_term)
          end
          if params[:sort_column].present? && @model.column_names.include?(params[:sort_column])
            sort_direction = %w[asc desc].include?(params[:sort_direction]) ? params[:sort_direction] : 'asc'
            all_records = all_records.order("#{params[:sort_column]} #{sort_direction}")
          end
          admin_ids = all_records.pluck(:admin_id).uniq
          @users_by_id = User.where(id: admin_ids).index_by(&:id)
        elsif @selected_table == 'news_items'
          # Charger TOUS les user_id avant pagination
          all_records = @model.all
          if params[:query].present?
            query_term = "%#{params[:query].downcase}%"
            conditions = @model.column_names.map { |col| "LOWER(CAST(#{col} AS TEXT)) LIKE :query" }.join(' OR ')
            all_records = all_records.where(conditions, query: query_term)
          end
          if params[:sort_column].present? && @model.column_names.include?(params[:sort_column])
            sort_direction = %w[asc desc].include?(params[:sort_direction]) ? params[:sort_direction] : 'asc'
            all_records = all_records.order("#{params[:sort_column]} #{sort_direction}")
          end
          user_ids = all_records.pluck(:user_id).uniq
          @users_by_id = User.where(id: user_ids).index_by(&:id)
        elsif @selected_table == 'reservations'
          # Charger TOUS les user_id et avion_id avant pagination
          all_records = @model.all
          if params[:query].present?
            query_term = "%#{params[:query].downcase}%"
            conditions = @model.column_names.map { |col| "LOWER(CAST(#{col} AS TEXT)) LIKE :query" }.join(' OR ')
            all_records = all_records.where(conditions, query: query_term)
          end
          if params[:sort_column].present? && @model.column_names.include?(params[:sort_column])
            sort_direction = %w[asc desc].include?(params[:sort_direction]) ? params[:sort_direction] : 'asc'
            all_records = all_records.order("#{params[:sort_column]} #{sort_direction}")
          end
          user_ids = all_records.pluck(:user_id).uniq
          avion_ids = all_records.pluck(:avion_id).uniq
          @users_by_id = User.where(id: user_ids).index_by(&:id)
          @avions_by_id = Avion.where(id: avion_ids).index_by(&:id)
        elsif @selected_table == 'signalements'
          # Charger TOUS les user_id et avion_id avant pagination
          all_records = @model.all
          if params[:query].present?
            query_term = "%#{params[:query].downcase}%"
            conditions = @model.column_names.map { |col| "LOWER(CAST(#{col} AS TEXT)) LIKE :query" }.join(' OR ')
            all_records = all_records.where(conditions, query: query_term)
          end
          if params[:sort_column].present? && @model.column_names.include?(params[:sort_column])
            sort_direction = %w[asc desc].include?(params[:sort_direction]) ? params[:sort_direction] : 'asc'
            all_records = all_records.order("#{params[:sort_column]} #{sort_direction}")
          end
          user_ids = all_records.pluck(:user_id).uniq
          avion_ids = all_records.pluck(:avion_id).uniq
          @users_by_id = User.where(id: user_ids).index_by(&:id)
          @avions_by_id = Avion.where(id: avion_ids).index_by(&:id)
        elsif @selected_table == 'transactions'
          # Charger TOUS les user_id avant pagination
          all_records = @model.all
          if params[:query].present?
            query_term = "%#{params[:query].downcase}%"
            conditions = @model.column_names.map { |col| "LOWER(CAST(#{col} AS TEXT)) LIKE :query" }.join(' OR ')
            all_records = all_records.where(conditions, query: query_term)
          end
          if params[:sort_column].present? && @model.column_names.include?(params[:sort_column])
            sort_direction = %w[asc desc].include?(params[:sort_direction]) ? params[:sort_direction] : 'asc'
            all_records = all_records.order("#{params[:sort_column]} #{sort_direction}")
          end
          user_ids = all_records.pluck(:user_id).uniq
          @users_by_id = User.where(id: user_ids).index_by(&:id)
        elsif @selected_table == 'vols'
          # Pour vols : charger TOUS les user_id et instructeur_id, avant pagination
          all_records = @model.all
          if params[:query].present?
            query_term = "%#{params[:query].downcase}%"
            conditions = @model.column_names.map { |col| "LOWER(CAST(#{col} AS TEXT)) LIKE :query" }.join(' OR ')
            all_records = all_records.where(conditions, query: query_term)
          end
          if params[:sort_column].present? && @model.column_names.include?(params[:sort_column])
            sort_direction = %w[asc desc].include?(params[:sort_direction]) ? params[:sort_direction] : 'asc'
            all_records = all_records.order("#{params[:sort_column]} #{sort_direction}")
          end
          user_ids = (all_records.pluck(:user_id) + all_records.pluck(:instructeur_id)).compact.uniq
          avion_ids = all_records.pluck(:avion_id).uniq
          @users_by_id = User.where(id: user_ids).index_by(&:id)
          @avions_by_id = Avion.where(id: avion_ids).index_by(&:id)
        end
      end
    end

    def show_record
      @table_name = params[:table_name]
      @model = create_anonymous_model(@table_name)
      @record = @model.find(params[:id])
      @associated_records = {}

      # Détecte les clés étrangères et charge les enregistrements associés pour un affichage plus riche.
      @model.columns.each do |column|
        if column.name.end_with?('_id') && column.name != 'id'
          associated_model_name = column.name.chomp('_id').classify
          begin
            associated_model_class = associated_model_name.constantize
            if associated_model_class < ActiveRecord::Base
              record_id = @record.send(column.name)
              if record_id.present?
                @associated_records[column.name] = associated_model_class.find_by(id: record_id)
              end
            end
          rescue NameError
            next # Ignore si le modèle déduit n'existe pas.
          end
        end
      end
    end

    def edit_record
      @table_name = params[:table_name]
      @model = create_anonymous_model(@table_name)
      @record = @model.find(params[:id])
      set_foreign_key_options
    end

    def update_record
      @table_name = params[:table_name]
      @model = create_anonymous_model(@table_name)
      @record = @model.find(params[:id])
      set_foreign_key_options # Pour que le formulaire puisse être re-rendu correctement en cas d'erreur
      if @record.update(record_params)
        redirect_to admin_tables_path(table_name: @table_name), notice: "L'enregistrement a été mis à jour avec succès."
      else
        render :edit_record, status: :unprocessable_entity
      end
    end

    def destroy_record
      table_name = params[:table_name]
      model = create_anonymous_model(table_name)
      record = model.find(params[:id])
      record.destroy

      redirect_to admin_tables_path(table_name: table_name), notice: "L'enregistrement a été supprimé avec succès."
    end



    private

    helper_method :translate_table_name
    def translate_table_name(table_name)
      translations = {
        'attendances' => 'Participants',
        'audios' => 'Podcasts',
        'avions' => 'Avions',
        'comments' => 'Commentaires',
        'courses' => 'Cours',
        'events' => 'Evènements',
        'flight_lessons' => 'Instruction',
        'news_items' => 'Consignes',
        'reservations' => 'Réservations',
        'signalements' => 'Signalements',
        'tarifs' => 'Tarifs',
        'transactions' => 'Comptabilité',
        'users' => 'Adhérents',
        'vols' => 'Vols'
      }
      translations.fetch(table_name, table_name.humanize)
    end


    def create_anonymous_model(table_name)
      # Crée une classe anonyme pour interagir avec n'importe quelle table.
      # La partie `model_name` est cruciale pour que les helpers de formulaire (form_with)
      # fonctionnent correctement avec un objet issu d'une classe anonyme.
      Class.new(ApplicationRecord) do
        self.table_name = table_name
        def self.model_name; ActiveModel::Name.new(self, nil, "Record") end

        # Ajoute dynamiquement des validations basées sur les propriétés des colonnes
        self.columns.each do |column|
          # Exclut les colonnes 'id', 'created_at', 'updated_at' des validations automatiques
          next if ['id', 'created_at', 'updated_at'].include?(column.name)

          # Validation de présence pour les colonnes NOT NULL
          unless column.null
            validates_presence_of column.name
          end

          # Validation de numericalité pour les types numériques
          if [:integer, :float, :decimal].include?(column.type)
            # allow_blank: true est utilisé pour éviter des erreurs en double si validates_presence_of est déjà appliqué
            validates_numericality_of column.name, allow_blank: true
          end

          # Validation de longueur pour les colonnes string/text avec une limite définie
          if [:string, :text].include?(column.type) && column.limit.present? && column.limit > 0
            validates_length_of column.name, maximum: column.limit, allow_blank: true
          end
        end
      end
    end

    def set_foreign_key_options
      @foreign_key_options = {}
      @model.columns.each do |column|
        # Vérifie si c'est une clé étrangère (se termine par _id, mais n'est pas 'id' lui-même)
        if column.name.end_with?('_id') && column.name != 'id'
          # Déduit le nom du modèle associé (ex: 'user_id' -> 'User')
          associated_model_name = column.name.chomp('_id').classify
          begin
            associated_model_class = associated_model_name.constantize
            # S'assure que c'est bien un modèle ActiveRecord
            if associated_model_class < ActiveRecord::Base
              # Détermine un attribut ou une méthode d'affichage approprié pour la liste déroulante
              if associated_model_class.column_names.include?('prenom') && associated_model_class.column_names.include?('nom')
                # Cas spécial pour les modèles avec prénom et nom (comme User)
                @foreign_key_options[column.name] = associated_model_class.all.map { |record| ["#{record.prenom} #{record.nom}", record.id] }
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
                @foreign_key_options[column.name] = associated_model_class.all.map { |record| [record.send(display_attribute).to_s, record.id] }
              end
            end
          rescue NameError # Si le modèle déduit n'existe pas, le traite comme un champ entier normal
            next
          end
        end
      end
    end

    def record_params
      # Permet dynamiquement à tous les attributs d'être mis à jour, sauf l'ID.
      excluded_params = ['id', 'created_at', 'updated_at']
      params.require(:record).permit(@model.column_names - excluded_params)
    end
  end
  
end
