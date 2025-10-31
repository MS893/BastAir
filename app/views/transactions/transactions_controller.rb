class TransactionsController < ApplicationController
  # Authentification requise pour toutes les actions
  before_action :authenticate_user!
  # Seul un trésorier ou un admin peut accéder à ce contrôleur
  before_action :authorize_tresorier!
  # Trouve la transaction pour les actions qui en ont besoin
  before_action :set_transaction, only: [:show, :edit, :update, :destroy]

  # GET /transactions
  def index
    @transactions = Transaction.order(date_transaction: :desc).page(params[:page]).per(20)
    total_recettes = Transaction.where(mouvement: 'Recette').sum(:montant)
    total_depenses = Transaction.where(mouvement: 'Dépense').sum(:montant)
    @solde_total = total_recettes - total_depenses
  end

  # GET /transactions/1
  def show
    # @transaction est déjà défini par set_transaction
  end

  # GET /transactions/new
  def new
    @transaction = Transaction.new
  end

  # POST /transactions
  def create
    @transaction = Transaction.new(transaction_params)
    if @transaction.save
      redirect_to @transaction, notice: 'La transaction a été créée avec succès.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /transactions/1/edit
  def edit
    # @transaction est déjà défini par set_transaction
  end

  # PATCH/PUT /transactions/1
  def update
    if @transaction.update(transaction_params)
      redirect_to @transaction, notice: 'La transaction a été mise à jour avec succès.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /transactions/1
  def destroy
    @transaction.destroy
    redirect_to transactions_url, notice: 'La transaction a été supprimée avec succès.'
  end

  private

  # Méthode pour trouver la transaction par son ID
  def set_transaction
    @transaction = Transaction.find(params[:id])
  end

  # Méthode d'autorisation pour le trésorier/admin
  def authorize_tresorier!
    unless current_user.admin? || current_user.fonction == 'tresorier'
      redirect_to root_path, alert: "Accès réservé aux administrateurs et au trésorier."
    end
  end

  # Strong Parameters pour sécuriser les données entrantes
  def transaction_params
    params.require(:transaction).permit(
      :user_id, :date_transaction, :description, :type_mouvement, :montant,
      :piece_justificative, :payment_method, :is_checked, :origine, :attachment_url, :mouvement
    )
  end
end