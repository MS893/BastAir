# app/controllers/web_push_subscriptions_controller.rb
class WebPushSubscriptionsController < ApplicationController
  before_action :authenticate_user!

  def create
    subscription_params = params.require(:subscription).permit(:endpoint, keys: [:p256dh, :auth])

    # On cherche une souscription existante pour cet endpoint pour éviter les doublons
    current_user.web_push_subscriptions.find_or_create_by!(
      endpoint: subscription_params[:endpoint],
      p256dh: subscription_params[:keys][:p256dh],
      auth: subscription_params[:keys][:auth]
    )

    head :ok
  end
end
