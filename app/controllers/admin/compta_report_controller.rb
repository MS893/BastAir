# frozen_string_literal: true

# app/controllers/admin/compta_report_controller.rb

module Admin
  class ComptaReportController < ApplicationController
    before_action :authorize_admin_or_treasurer!

    def treasury_report
      # 1. Récupérer toutes les transactions du modèle ActiveRecord
      transactions = Transaction.all

      # 2. Instancier votre gestionnaire de trésorerie (en utilisant les données réelles)
      # L'initial_balance devrait être le solde de fin d'exercice précédent
      initial_balance = BigDecimal('150.75')
      manager = TreasuryManager.new(initial_balance)

      # 3. Charger les transactions dans le gestionnaire
      transactions.each do |t|
        # NOTE: La Transaction doit être transformée pour être compatible avec la classe Manager si elle n'est pas refactorisée.
        # Idéalement, le Manager travaillerait directement avec la collection ActiveRecord.
        manager.add_transaction(t)
      end

      # 4. Exécuter la logique métier et assigner les variables d'instance
      @report_data = manager.generate_report
      @current_balance = manager.current_balance
    end

    def yearly_accounting_report
      # On récupère l'année depuis les paramètres, ou on utilise l'année en cours par défaut.
      @year = params[:year].present? ? params[:year].to_i : Date.current.year

      # On prépare la liste des années disponibles pour le menu déroulant.
      first_transaction_year = Transaction.minimum(:date_transaction)&.year || Date.current.year
      @available_years = (first_transaction_year..Date.current.year).to_a.reverse

      # --- Calculs pour l'exercice N (année sélectionnée) ---
      transactions_n = Transaction.where(date_transaction: Date.new(@year).all_year)
      @recettes_n = transactions_n.where(mouvement: 'Recette').sum(:montant)
      @depenses_n = transactions_n.where(mouvement: 'Dépense').sum(:montant)
      @resultat_exercice_n = @recettes_n - @depenses_n

      # --- Calculs pour les Immobilisations et Amortissements (N) ---
      immobilisations_acquises_n = Immobilisation.where('date_acquisition <= ?', Date.new(@year).end_of_year)
      @valeur_brute_immos_n = immobilisations_acquises_n.sum(:valeur_acquisition)
      @amortissements_cumules_n = immobilisations_acquises_n.sum { |immo| immo.amortissements_cumules(@year) }
      @dotation_amortissement_n = immobilisations_acquises_n.sum(&:amortissement_annuel)
      @valeur_nette_immos_n = @valeur_brute_immos_n - @amortissements_cumules_n

      # --- Détails pour le Compte de Résultat (N) ---
      @recettes_n_details = transactions_n.where(mouvement: 'Recette').group(:source_transaction).sum(:montant)
      @depenses_n_details = transactions_n.where(mouvement: 'Dépense').group(:source_transaction).sum(:montant)
      # On fusionne les clés pour avoir toutes les catégories possibles
      @all_categories = @recettes_n_details.keys | @depenses_n_details.keys

      # --- Calculs pour l'exercice N-1 (année précédente) ---
      @year_n_minus_1 = @year - 1
      transactions_n_minus_1 = Transaction.where(date_transaction: Date.new(@year_n_minus_1).all_year)
      @recettes_n_minus_1 = transactions_n_minus_1.where(mouvement: 'Recette').sum(:montant)
      @depenses_n_minus_1 = transactions_n_minus_1.where(mouvement: 'Dépense').sum(:montant)
      @resultat_exercice_n_minus_1 = @recettes_n_minus_1 - @depenses_n_minus_1

      # --- Calculs pour les Immobilisations et Amortissements (N-1) ---
      immobilisations_acquises_n_minus_1 = Immobilisation.where('date_acquisition <= ?',
                                                                Date.new(@year_n_minus_1).end_of_year)
      @valeur_brute_immos_n_minus_1 = immobilisations_acquises_n_minus_1.sum(:valeur_acquisition)
      @amortissements_cumules_n_minus_1 = immobilisations_acquises_n_minus_1.sum do |immo|
        immo.amortissements_cumules(@year_n_minus_1)
      end
      @dotation_amortissement_n_minus_1 = immobilisations_acquises_n_minus_1.sum(&:amortissement_annuel)
      @valeur_nette_immos_n_minus_1 = @valeur_brute_immos_n_minus_1 - @amortissements_cumules_n_minus_1

      # --- Détails pour le Compte de Résultat (N-1) ---
      @recettes_n_minus_1_details = transactions_n_minus_1.where(mouvement: 'Recette').group(:source_transaction).sum(:montant)
      @depenses_n_minus_1_details = transactions_n_minus_1.where(mouvement: 'Dépense').group(:source_transaction).sum(:montant)
      @all_categories |= @recettes_n_minus_1_details.keys | @depenses_n_minus_1_details.keys

      # --- Calculs du Passif (Fonds propres) ---
      # Fonds propres au début de N-1 (solde de toutes les années avant N-1)
      # On utilise une comparaison de date directe pour la compatibilité avec SQLite.
      @fonds_propres_debut_n_minus_1 = Transaction.where('date_transaction < ?',
                                                         Date.new(@year_n_minus_1)).sum("CASE WHEN mouvement = 'Recette' THEN montant ELSE -montant END")
      # Fonds propres au début de N (solde de toutes les années avant N)
      @fonds_propres_debut_n = @fonds_propres_debut_n_minus_1 + @resultat_exercice_n_minus_1

      # --- Calculs de l'Actif (Trésorerie) ---
      # Trésorerie à la fin de N-1 et N
      @tresorerie_fin_n_minus_1 = @fonds_propres_debut_n - @valeur_nette_immos_n_minus_1
      @tresorerie_fin_n = @fonds_propres_debut_n + @resultat_exercice_n - @valeur_nette_immos_n

      # On met à jour le résultat de l'exercice pour inclure les dotations aux amortissements
      @resultat_exercice_n -= @dotation_amortissement_n
      @resultat_exercice_n_minus_1 -= @dotation_amortissement_n_minus_1

      respond_to do |format|
        format.html
        format.pdf do
          render  pdf: "Bilan-Comptable-BastAir-#{@year}",
                  layout: 'pdf',
                  encoding: 'UTF-8',
                  page_size: 'A4',
                  orientation: 'Portrait',
                  margin: { top: 30, bottom: 20, left: 15, right: 15 },
                  header: { html: { template: 'layouts/_pdf_bilan_header', layout: false, formats: [:html] },
                            spacing: 10 },
                  footer: { html: { template: 'layouts/_pdf_footer', layout: false, formats: [:html] } },
                  # On force l'exécution du JS pour le logo et la pagination
                  extra_options: { 'enable-local-file-access': true, 'enable-javascript': true,
                                   'javascript-delay': 100 }
        end
      end
    end

    private

    def authorize_admin_or_treasurer!
      return if current_user&.admin? || current_user&.fonction == 'tresorier'

      redirect_to root_path,
                  alert: "Vous n'avez pas les droits pour accéder à cette page."
    end
  end
end
