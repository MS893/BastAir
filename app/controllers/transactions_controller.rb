class TransactionsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_treasurer_or_admin! # S'applique à toutes les actions
  before_action :set_transaction, only: %i[show edit update destroy toggle_check]
  # Empêche la modification ou suppression d'une transaction déjà vérifiée
  before_action :prevent_modification_if_checked, only: %i[edit update destroy]

  def index
    @transactions = Transaction.includes(:user).all # Eager loading pour optimiser

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

    # Calcule les totaux basés sur les transactions filtrées
    @solde_total = @transactions.sum("CASE WHEN mouvement = 'Recette' THEN montant ELSE -montant END")
    @total_recettes = @transactions.where(mouvement: 'Recette').sum(:montant)
    @total_depenses = @transactions.where(mouvement: 'Dépense').sum(:montant)

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

    # Ordonne les résultats
    @transactions = @transactions.order(date_transaction: :desc)

    respond_to do |format|
      format.html { @transactions = @transactions.page(params[:page]).per(15) } # On pagine uniquement pour la vue HTML
      format.csv { send_data Transaction.to_csv(@transactions), filename: "export-transactions-#{Date.today}.csv" }
    end
  end

  def analytics
    @years = Transaction.pluck(Arel.sql("strftime('%Y', date_transaction)")).uniq.sort.reverse
    @selected_year = params[:year].present? ? params[:year].to_i : Date.today.year

    transactions_for_year = Transaction.where("strftime('%Y', date_transaction) = ?", @selected_year.to_s)
    transactions_for_previous_year = Transaction.where("strftime('%Y', date_transaction) = ?", (@selected_year - 1).to_s)

    # Données pour le graphique en barres (Recettes vs Dépenses par mois)
    recettes_by_month = transactions_for_year.where(mouvement: 'Recette')
                                              .group("strftime('%m', date_transaction)")
                                              .sum(:montant)

    # --- NOUVEAU GRAPHIQUE DE COMPARAISON ---
    # 1. Récupérer les recettes de l'année précédente
    recettes_by_month_previous_year = transactions_for_previous_year.where(mouvement: 'Recette')
                                                                    .group("strftime('%m', date_transaction)")
                                                                    .sum(:montant)

    # 2. Préparer les données pour le graphique de comparaison
    month_names = I18n.t('date.month_names', default: []).drop(1) # Mois de Janvier à Décembre
    current_year_revenue = month_names.map.with_index { |name, i| [name, recettes_by_month[(i + 1).to_s.rjust(2, '0')] || 0] }.to_h
    previous_year_revenue = month_names.map.with_index { |name, i| [name, recettes_by_month_previous_year[(i + 1).to_s.rjust(2, '0')] || 0] }.to_h

    @revenue_comparison_data = [
      { name: "Recettes #{@selected_year}", data: current_year_revenue },
      { name: "Recettes #{@selected_year - 1}", data: previous_year_revenue }
    ]
    # --- FIN DU NOUVEAU GRAPHIQUE ---


    depenses_by_month = transactions_for_year.where(mouvement: 'Dépense')
                                              .group("strftime('%m', date_transaction)")
                                              .sum(:montant)

    # Formater les données pour Chartkick avec les noms des mois en français
    month_names = I18n.t('date.month_names', default: [])
    @monthly_data = [
      { name: 'Recettes', data: recettes_by_month.transform_keys { |m| month_names[m.to_i] } },
      { name: 'Dépenses', data: depenses_by_month.transform_keys { |m| month_names[m.to_i] } }
    ]

    # --- GRAPHIQUES DE RÉPARTITION ---
    # Données pour le camembert (Répartition des RECETTES par source)
    @income_by_source = transactions_for_year.where(mouvement: 'Recette').group(:source_transaction).sum(:montant)

    # Données pour le camembert (Répartition des DÉPENSES par source)
    @expenses_by_source = transactions_for_year.where(mouvement: 'Dépense').group(:source_transaction).sum(:montant)

    # Données pour le camembert (Répartition des DÉPENSES par méthode de paiement)
    @expenses_by_payment_method = transactions_for_year.where(mouvement: 'Dépense').group(:payment_method).sum(:montant)

    # Données pour le graphique du solde cumulé
    # 1. Calculer le solde au début de l'année sélectionnée
    balance_at_start_of_year = Transaction.where("strftime('%Y', date_transaction) < ?", @selected_year.to_s)
                                          .sum("CASE WHEN mouvement = 'Recette' THEN montant ELSE -montant END")

    # 2. Obtenir les changements nets par jour pour l'année sélectionnée
    daily_net_changes = transactions_for_year.group("date(date_transaction)")
                                              .sum("CASE WHEN mouvement = 'Recette' THEN montant ELSE -montant END")

    # 3. Construire le graphique du solde cumulé
    @cumulative_balance_data = build_cumulative_data(balance_at_start_of_year, daily_net_changes)
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

  # Action pour marquer une transaction comme vérifiée/non vérifiée
  def toggle_check
    # @transaction est déjà chargé par le before_action
    @transaction.toggle!(:is_checked)

    respond_to do |format|
      format.turbo_stream do
        # On renvoie un Turbo Stream qui remplacera la ligne de la transaction
        render turbo_stream: turbo_stream.replace(@transaction)
      end
      format.html { redirect_to transactions_path, notice: 'Statut de la transaction mis à jour.' }
    end
  end


  
  private

  def set_transaction
    @transaction = Transaction.find(params[:id])
  end

  def transaction_params
    params.require(:transaction).permit(:date_transaction, :description, :mouvement, :montant, :source_transaction, :payment_method, :user_id, :is_checked)
  end

  # Méthode de sécurité pour empêcher la modification des transactions vérifiées
  def prevent_modification_if_checked
    if @transaction.is_checked?
      redirect_to transactions_path, alert: "Action impossible : cette transaction est déjà vérifiée et ne peut être ni modifiée, ni supprimée."
    end
  end

  # visualiser l'évolution du solde au fil du temps
  def build_cumulative_data(starting_balance, daily_changes)
    cumulative_balance_data = {}
    sorted_changes = daily_changes.sort_by { |date, _| date }
    sorted_changes.each do |date, change|
      starting_balance += change
      cumulative_balance_data[date] = starting_balance
    end
    cumulative_balance_data
  end
end
