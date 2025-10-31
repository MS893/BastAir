class ReportsController < ApplicationController
  def treasury_report
    # 1. Récupérer toutes les transactions du modèle ActiveRecord
    transactions = Transaction.all 
    
    # 2. Instancier votre gestionnaire de trésorerie (en utilisant les données réelles)
    # L'initial_balance devrait être le solde de fin d'exercice précédent
    initial_balance = BigDecimal("150.75") 
    manager = TreasuryManager.new(initial_balance)
    
    # 3. Charger les transactions dans le gestionnaire
    transactions.each do |t|
      # Note: La Transaction doit être transformée pour être compatible avec la classe Manager si elle n'est pas refactorisée.
      # Idéalement, le Manager travaillerait directement avec la collection ActiveRecord.
      manager.add_transaction(t) 
    end

    # 4. Exécuter la logique métier
    @report_data = manager.generate_report 
    @current_balance = manager.current_balance
  end
end