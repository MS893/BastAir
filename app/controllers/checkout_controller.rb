# frozen_string_literal: true

class CheckoutController < ApplicationController
  before_action :authenticate_user!

  def create
    # Valider le montant uniquement pour l'option "Montant libre"
    if params[:description] == 'Montant choisi pour créditer mon compte BastAir' && params[:amount].to_f <= 0
      flash[:alert] = 'Montant incorrect'
      redirect_to credit_path
      return
    end

    # Ajout des frais de transaction de 2€ au montant
    # Le montant est envoyé en euros, il faut le convertir en centimes pour Stripe
    amount_in_cents = ((params[:amount].to_f + 2.0) * 100).to_i

    session = Stripe::Checkout::Session.create(
      payment_method_types: ['card'],
      client_reference_id: current_user.id,
      line_items: [{
        price_data: {
          currency: 'eur',
          product_data: {
            name: params[:description] || 'Crédit BastAir'
          },
          unit_amount: amount_in_cents
        },
        quantity: 1
      }],
      mode: 'payment',
      # option pour demander à Stripe d'inclure les line_items dans l'objet session pour le webhook (permet de récupérer le montant payé)
      expand: ['line_items'],
      success_url: "#{root_url}?success=true",
      cancel_url: "#{root_url}?canceled=true",
      metadata: {
        user_id: current_user.id,
        intended_base_amount: params[:amount].to_f # Stocke le montant initialement choisi par l'utilisateur (avant les fraisde 2€)
      }
    )

    redirect_to session.url, allow_other_host: true
  end
end
