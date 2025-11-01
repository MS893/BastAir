class TransactionsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_treasurer_or_admin!
  before_action :set_transaction, only: %i[show edit update destroy]

  def index
    @transactions = Transaction.all

    @selected_month = params[:month]
    @selected_year = params[:year]
    @selected_source = params[:source]

    if @selected_month.present?
      @transactions = @transactions.where("strftime('%m', date_transaction) = ?", @selected_month.to_s.rjust(2, '0'))
    end

    if @selected_year.present?
      @transactions = @transactions.where("strftime('%Y', date_transaction) = ?", @selected_year.to_s)
    end

    if @selected_source.present?
      @transactions = @transactions.where(source_transaction: @selected_source)
    end

    # Calcule le solde total basé sur les transactions filtrées
    @solde_total = @transactions.sum("CASE WHEN mouvement = 'Recette' THEN montant ELSE -montant END")

    # Construit le titre dynamique pour la carte du solde
    title_parts = []
    title_parts << l(Date.new(2000, @selected_month.to_i), format: '%B') if @selected_month.present?
    title_parts << @selected_year if @selected_year.present?
    
    if @selected_source.present?
      title_parts << "(#{@selected_source})"
    end

    @solde_title = if title_parts.any?
                      "Solde pour #{title_parts.join(' ')}"
                    else
                      "Solde Total Actuel"
                    end

    # Ordonne et pagine les résultats filtrés
    @transactions = @transactions.order(date_transaction: :desc).page(params[:page]).per(15)
  end

  def analytics
    @years = Transaction.pluck(Arel.sql("strftime('%Y', date_transaction)")).uniq.sort.reverse
    @selected_year = params[:year].present? ? params[:year].to_i : Date.today.year

    transactions_for_year = Transaction.where("strftime('%Y', date_transaction) = ?", @selected_year.to_s)

    # Données pour le graphique en barres (Recettes vs Dépenses par mois)
    recettes_by_month = transactions_for_year.where(mouvement: 'Recette')
                                              .group("strftime('%m', date_transaction)")
                                              .sum(:montant)

    depenses_by_month = transactions_for_year.where(mouvement: 'Dépense')
                                              .group("strftime('%m', date_transaction)")
                                              .sum(:montant)

    # Formater les données pour Chartkick avec les noms des mois en français
    month_names = I18n.t('date.month_names', default: [])
    @monthly_data = [
      { name: 'Recettes', data: recettes_by_month.transform_keys { |m| month_names[m.to_i] } },
      { name: 'Dépenses', data: depenses_by_month.transform_keys { |m| month_names[m.to_i] } }
    ]

    # Données pour le camembert (Répartition par source)
    @source_data = transactions_for_year.group(:source_transaction).sum(:montant)

    # Données pour le graphique du solde cumulé
    # 1. Calculer le solde au début de l'année sélectionnée
    balance_at_start_of_year = Transaction.where("strftime('%Y', date_transaction) < ?", @selected_year.to_s)
                                          .sum("CASE WHEN mouvement = 'Recette' THEN montant ELSE -montant END")

    # 2. Obtenir les changements nets par jour pour l'année sélectionnée
    daily_net_changes = transactions_for_year.group("date(date_transaction)")
                                              .sum("CASE WHEN mouvement = 'Recette' THEN montant ELSE -montant END")

    # 3. Construire le graphique du solde cumulé
    @cumulative_balance_data = {}
    daily_net_changes.sort_by { |date, _| date }.each do |date, change|
      balance_at_start_of_year += change
      @cumulative_balance_data[date] = balance_at_start_of_year
    end
  end

  def show
  end

  def new
    @transaction = Transaction.new
    @users = User.order(:prenom, :nom)
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
    @users = User.order(:prenom, :nom)
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