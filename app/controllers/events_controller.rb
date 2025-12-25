class EventsController < ApplicationController
  before_action :authenticate_user!, only: %i[new create edit update destroy confirm_destroy] # l'utilisateur est connecté
  before_action :set_event, only: %i[show edit update destroy confirm_destroy]
  before_action :authorize_admin!, only: %i[new create edit update destroy confirm_destroy delete_past] # seul un admin peut gérer les événements
  before_action :combine_date_and_time, only: %i[ create update ]

  def index
    @events = Event.order(start_date: :asc)
    # Cette action rendra la vue app/views/events/index.html.erb
  end

  def show
    # @event est déjà défini par set_event
  end

  def new
    @event = Event.new
  end

  def create
    @event = Event.new(event_params)
    # On associe l'administrateur actuel à l'événement
    @event.admin = current_user
    
    # On s'assure que le prix est à 0 s'il n'est pas spécifié
    @event.price ||= 0

    if @event.save
      # --- Synchronisation avec Google Calendar ---
      GoogleCalendarService.new.create_event_for_app(@event)

      redirect_to root_path, notice: "L'événement a été créé avec succès."
    else
      render :new, status: ::unprocessable_content
    end
  end

  def edit
    # @event est déjà défini par set_event
  end

  def update
    if @event.update(event_params)
      # on envoie un email pour informer les participants de l'event de la modif
      @event.users.each do |participant|
        # --- Synchronisation avec Google Calendar ---
        GoogleCalendarService.new.update_google_event_for_app_event(@event)
        
        UserMailer.event_updated_notification(participant, @event).deliver_later
      end
      redirect_to @event, notice: "L'événement a été mis à jour avec succès."
    else
      render :edit, status: ::unprocessable_content
    end
  end

  def destroy
    # on charge les participants et les infos de l'événement en mémoire AVANT de le détruire
    participants = @event.users.to_a
    event_title = @event.title
    was_paid = !@event.is_free?
    # ceci pour pouvoir envoyer des emails informant les participants de la suppression de l'événement
    participants.each do |participant|
      UserMailer.event_destroyed_notification(participant, event_title, was_paid).deliver_later
    end

    # --- Synchronisation avec Google Calendar ---
    GoogleCalendarService.new.delete_google_event_for_app_event(@event)

    @event.destroy
    redirect_to events_path, notice: "L'événement a été supprimé avec succès."
  end

  def confirm_destroy
    # on affiche la view `confirm_destroy.html.erb`
    # @event est déjà défini par `set_event`
  end

  # Action pour supprimer manuellement les anciens événements
  def delete_past
    # On sélectionne les événements à supprimer :
    # - Dont la date de début est antérieure à aujourd'hui.
    # - Dont le titre n'est PAS "Objets trouvés".
    events_to_delete = Event.where("start_date < ?", Time.zone.now.beginning_of_day)
                            .where.not(title: "Objets trouvés")
    
    count = events_to_delete.destroy_all.size
    redirect_to events_path, notice: "#{count} événement(s) passé(s) ont été supprimé(s)."
  end
  


  private

  def set_event
    @event = Event.find(params[:id])
  end

  def combine_date_and_time
    if params[:event][:start_date].present? && params[:event][:start_date_hour].present? && params[:event][:start_date_minute].present?
      date = Date.parse(params[:event][:start_date])
      hour = params[:event][:start_date_hour].to_i
      minute = params[:event][:start_date_minute].to_i
      
      # On reconstruit le paramètre start_date avec la date et l'heure
      # avant qu'il ne soit utilisé par event_params
      params[:event][:start_date] = Time.zone.local(date.year, date.month, date.day, hour, minute)
    end
  end

  def event_params
    params.require(:event).permit(:title, :description, :start_date, :price, :photo)
  end

end
