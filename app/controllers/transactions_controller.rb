class TransactionsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_treasurer_or_admin!
  before_action :set_transaction, only: %i[show edit update destroy]

  def index
    @transactions = Transaction.all

    @selected_month = params[:month]
    @selected_year = params[:year]

    if @selected_month.present?
      @transactions = @transactions.where("strftime('%m', date_transaction) = ?", @selected_month.to_s.rjust(2, '0'))
    end

    if @selected_year.present?
      @transactions = @transactions.where("strftime('%Y', date_transaction) = ?", @selected_year.to_s)
    end

    # Calcule le solde total basé sur les transactions filtrées
    @solde_total = @transactions.sum("CASE WHEN mouvement = 'Recette' THEN montant ELSE -montant END")

    # Ordonne et pagine les résultats filtrés
    @transactions = @transactions.order(date_transaction: :desc).page(params[:page]).per(15)
  end

  def show
  end

  def new
    @transaction = Transaction.new
  end

  def create
    @transaction = Transaction.new(transaction_params)
    if @transaction.save
      redirect_to @transaction, notice: 'La transaction a été créée avec succès.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @transaction.update(transaction_params)
      redirect_to @transaction, notice: 'La transaction a été mise à jour avec succès.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @transaction.destroy
    redirect_to transactions_url, notice: 'La transaction a été supprimée avec succès.'
  end

  private

  def set_transaction
    @transaction = Transaction.find(params[:id])
  end

  def transaction_params
    params.require(:transaction).permit(:date_transaction, :description, :mouvement, :montant, :source_transaction, :payment_method, :user_id, :is_checked)
  end
end