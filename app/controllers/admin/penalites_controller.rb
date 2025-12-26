# frozen_string_literal: true

# app/controllers/admin/penalites_controller.rb
module Admin
  class PenalitesController < ApplicationController
    before_action :authorize_admin!
    before_action :set_penalite

    # Action pour appliquer une pénalité
    def apply
      # On vérifie que la pénalité n'est pas déjà appliquée pour éviter les doublons
      if @penalite.status == 'Appliquée'
        redirect_to admin_show_table_record_path(table_name: 'penalites', id: @penalite.id),
                    alert: 'Cette pénalité a déjà été appliquée.'
      else
        # On crée la transaction de débit sur le compte de l'utilisateur
        Transaction.create!(
          user: @penalite.user,
          date_transaction: Time.zone.today,
          description: "Pénalité pour annulation tardive du vol du #{l(@penalite.reservation_start_time,
                                                                      format: :short_year_time)}",
          mouvement: 'Dépense',
          montant: @penalite.penalty_amount,
          source_transaction: 'Charges Exceptionnelles',
          payment_method: 'Prélèvement sur compte'
        )

        # On met à jour le statut de la pénalité et on enregistre quel admin a fait l'action
        @penalite.update(status: 'Appliquée', admin: current_user)

        # On envoie un email à l'utilisateur pour le notifier
        UserMailer.penalty_applied_notification(@penalite.user, @penalite).deliver_later

        redirect_to admin_show_table_record_path(table_name: 'penalites', id: @penalite.id),
                    notice: "La pénalité de #{@penalite.penalty_amount} € a été appliquée au compte de #{@penalite.user.name}."
      end
    end

    # Action pour annuler une pénalité
    def cancel
      # Si la pénalité avait déjà été appliquée, il faut recréditer le compte
      # on supprime la transaction de débit originale, et pas créer une nouvelle transaction de crédit.
      if @penalite.status == 'Appliquée'
        # On cherche la transaction de débit originale associée à cette pénalité
        original_debit_transaction = Transaction.find_by(
          user: @penalite.user,
          mouvement: 'Dépense',
          montant: @penalite.penalty_amount,
          description: "Pénalité pour annulation tardive du vol du #{l(@penalite.reservation_start_time,
                                                                       format: :short_year_time)}"
        )

        if original_debit_transaction
          original_debit_transaction.destroy
          flash[:notice] = 'La pénalité a été retirée.'
        else
          # Cas où la transaction originale n'est pas trouvée (devrait être rare si le flux est respecté)
          flash[:alert] =
            "La pénalité correspondante n'a pas été trouvée. Le compte de l'utilisateur n'a pas été recrédité."
        end
      end

      @penalite.update(status: 'Annulée', admin: current_user)
      redirect_to admin_show_table_record_path(table_name: 'penalites', id: @penalite.id),
                  notice: 'La pénalité a été annulée.'
    end

    private

    def set_penalite
      @penalite = Penalite.find(params[:id])
    end
  end
end
