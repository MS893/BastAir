class StripeWebhooksController < ApplicationController
  # Stripe envoie des requêtes sans token CSRF, il faut donc le désactiver pour cette action.
  skip_before_action :verify_authenticity_token

  def create
    payload = request.body.read
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']
    endpoint_secret = Rails.application.credentials.dig(:stripe, :webhooks_secret)

    unless endpoint_secret
      puts "💥 Webhook secret not found. Make sure you have set `config.credentials.stripe.webhook_secret`"
      render json: { error: "Webhook secret not configured" }, status: 500
      return
    end
    event = nil

    begin
      event = Stripe::Webhook.construct_event(
        payload, sig_header, endpoint_secret
      )
    rescue JSON::ParserError => e
      # Le payload JSON est invalide
      render json: { error: "Invalid payload" }, status: 400
      return
    rescue Stripe::SignatureVerificationError => e
      # La signature est invalide
      render json: { error: "Invalid signature" }, status: 400
      return
    end

    # Gérer l'événement
    case event.type
    when 'checkout.session.completed'
      session = event.data.object
      # Gère les paiements synchrones (la plupart des cartes)
      handle_checkout_session(session) if session.payment_status == 'paid' # On vérifie que le paiement est bien passé
    when 'checkout.session.async_payment_succeeded'
      puts "1. paiement Stripe réussi"
      session = event.data.object
      # Gère les paiements asynchrones (virements, etc.)
      handle_checkout_session(session)
    else
      puts "Unhandled event type: #{event.type}"
    end

    render json: { message: :success }, status: 200
  end


  
  private

  def handle_checkout_session(session)
    # Encapsuler toute la logique dans un bloc de secours pour capturer n'importe quelle erreur
    begin
      # Récupérer l'ID de l'utilisateur depuis les métadonnées de la session
      # Il est nécessaire de récupérer la session à nouveau pour pouvoir expand les line_items
      # car ils ne sont pas inclus par défaut dans l'événement webhook.
      session_with_line_items = Stripe::Checkout::Session.retrieve(
        id: session.id,
        expand: ['line_items']
      )
      user = User.find_by(id: session.metadata.user_id)
      unless user
        puts "Webhook Error: User not found with id #{session.metadata.user_id}"
        return
      end

      puts "2. dans handle_checkout_session"
      # CORRECTION: La description est dans le nom du produit du premier 'line_item'.
      # Lorsque product_data est utilisé, `product` est un ID de produit (chaîne de caractères),
      # pas un objet. La description est directement accessible sur le line_item.
      line_item = session_with_line_items.line_items.data.first
      description = line_item&.description
      unless description
        puts "Webhook Error: Product description not found in session #{session.id}"
        return
      end

      # On récupère le montant de base initialement voulu par l'utilisateur (avant frais Stripe)
      # pour les cas de test où session.amount_total est 0.
      intended_base_amount = session.metadata.intended_base_amount.to_d

      tarif_horaire = Tarif.order(annee: :desc).first&.tarif_horaire_avion1 || 150 # 150€ comme valeur par défaut
      prix_bloc_6h = 6 * (tarif_horaire - 5)
      prix_bloc_10h = 10 * (tarif_horaire - 10)

      amount_to_credit = case description
      when "PAIEMENT DE TEST"
        # Crédite un montant fixe de 100€ pour ce cas de test
        100.0.to_d
      when "Achat d'un bloc de 6h de vol pour mon compte BastAir"
        # On crédite le prix du bloc + le bonus de 30€
        prix_bloc_6h.to_d + 30.0.to_d
      when "Achat d'un bloc de 10h de vol pour mon compte BastAir"
        # On crédite le prix du bloc + le bonus de 100€
        prix_bloc_10h.to_d + 100.0.to_d
      when "Montant choisi pour créditer mon compte BastAir"
        # Pour le montant libre, on crédite le montant initialement choisi par l'utilisateur
        # (avant l'ajout des frais Stripe), surtout utile pour les tests où amount_total peut être 0.
        intended_base_amount.to_d
      else
        # Cas de fallback ou description non reconnue.
        # Si amount_total est 0 (test), on crédite 0 pour éviter des soldes négatifs inattendus.
        # Sinon, on prend le montant payé moins les frais.
        session.amount_total == 0 ? 0.0.to_d : (session.amount_total / 100.0).to_d - 2.0.to_d
      end

      # On s'assure que le montant à créditer est bien un nombre
      return if amount_to_credit.nil? || amount_to_credit.nan?

      puts "Attempting to credit user #{user.email} with #{amount_to_credit}€ for product: '#{description}'"

      # On appelle la méthode centralisée sur le modèle User pour créditer le compte.
      # La transaction, le verrouillage et la diffusion Turbo Stream sont gérés par le modèle.
      user.credit_account(amount_to_credit)
      puts "✅ User #{user.email} successfully credited. New balance: #{user.reload.solde}"
    rescue => e
      # Si une erreur se produit, on l'affiche dans les logs pour le diagnostic
      puts "💥 Webhook Error: Failed to handle checkout session #{session.id}. Error: #{e.message}"
      puts e.backtrace.join("\n")
    end
  end

end
