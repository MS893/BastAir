class EventsController < ApplicationController
  before_action :authenticate_user!, only: %i[new create edit update destroy confirm_destroy] # l'utilisateur est connecté
  before_action :set_event, only: %i[show edit update destroy confirm_destroy]
  before_action :authorize_admin!, only: %i[new create edit update destroy confirm_destroy] # seul un admin peut gérer les événements

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

    if @event.save
      redirect_to root_path, notice: "L'événement a été créé avec succès."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # @event est déjà défini par set_event
  end

  def update
    if @event.update(event_params)
      # on envoie un email pour informer les participants de l'event de la modif
      @event.users.each do |participant|
        UserMailer.event_updated_notification(participant, @event).deliver_later
      end
      redirect_to @event, notice: "L'événement a été mis à jour avec succès."
    else
      render :edit, status: :unprocessable_entity
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

    @event.destroy
    redirect_to events_path, notice: "L'événement a été supprimé avec succès."
  end

  def confirm_destroy
    # on affiche la view `confirm_destroy.html.erb`
    # @event est déjà défini par `set_event`
  end

  
  private

  def set_event
    @event = Event.find(params[:id])
  end

  def event_params
    params.require(:event).permit(:title, :description, :start_date, :price, :photo)
  end
  
  # pour autoriser uniquement les administrateurs à accéder à certaines actions
  def authorize_admin!
    redirect_to root_path, alert: "Accès réservé aux administrateurs." unless current_user&.admin?
  end

end
