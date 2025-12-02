class CommentsController < ApplicationController
  
  before_action :set_event
  before_action :authenticate_user!
  before_action :set_comment, only: [:edit, :update, :destroy]
  before_action :check_author, only: [:edit, :update, :destroy]

  def create
    # On vérifie si l'utilisateur a déjà commenté cet événement
    if @event.comments.exists?(user_id: current_user.id)
      redirect_to event_path(@event), alert: "Vous avez déjà laissé un commentaire pour cet événement."
      return
    end

    @comment = @event.comments.new(comment_params)
    # on associe le commentaire à l'utilisateur actuellement connecté
    @comment.user = current_user    
    if @comment.save
      redirect_to event_path(@event), notice: 'Commentaire ajouté !'
    else
      # Si la sauvegarde échoue, on redirige avec une alerte.
      redirect_to event_path(@event), alert: 'Le commentaire ne peut pas être vide.'
    end
  end

  def edit
    # @comment est déjà chargé par le before_action
  end

  def update
    if @comment.update(comment_params)
      redirect_to event_path(@event), notice: 'Commentaire mis à jour.'
    else
      # status: :unprocessable_entity indique au navigateur que la soumission du formulaire a échoué (code HTTP 422)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @comment.destroy
    redirect_to event_path(@event), notice: 'Commentaire supprimé.', status: :see_other
  end



  private
  def set_event
    @event = Event.find(params[:event_id])
  end
  def set_comment
    @comment = @event.comments.find(params[:id])
  end
  def comment_params
    params.require(:comment).permit(:content)
  end
  def check_author
    # @comment est déjà chargé par le before_action :set_comment
    unless current_user == @comment.user
      redirect_to event_path(@event), flash: { danger: "Action impossible" }
    end
  end

end
