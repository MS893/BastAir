# config/routes.rb
Rails.application.routes.draw do

  # --- Routes pour les utilisateurs et l'authentification ---
  resources :users, only: [:index, :show, :edit, :update], constraints: { id: /\d+/ } do
    collection do
      get :search # Ajoute la route GET /users/search
    end
    get 'vols', on: :member # Ajoute la route GET /users/:id/vols
    resources :avatars, only: [:create]
  end

  # Configuration de Devise :
  # On désactive la création de compte publique (gérée par l'admin).
  # On regroupe les routes de Devise ici pour éviter les conflits.
  devise_for :users, 
    path: 'auth', # On préfixe les routes Devise avec 'auth' pour éviter les conflits (ex: /auth/sign_in)
    skip: [:registrations], # On désactive les routes d'inscription publiques publiques
    controllers: { 
      sessions: 'users_auth/sessions', # Contrôleur personnalisé pour la connexion (avec reCAPTCHA)
      passwords: 'users_auth/passwords' # Contrôleur personnalisé pour les mots de passe
    }

  # On recrée manuellement les routes pour que les utilisateurs puissent modifier leur profil,
  # tout en utilisant le contrôleur par défaut de Devise pour les registrations.
  as :user do
    get 'users/edit' => 'devise/registrations#edit', as: 'edit_user_registration'
    put 'users' => 'devise/registrations#update', as: 'user_registration'
    get 'users/sign_out' => 'users_auth/sessions#destroy', as: 'destroy_user_session_get'
  end

  get 'agenda', to: 'reservations#agenda'
  get 'faq', to: 'static_pages#faq'
  get 'check_list', to: 'static_pages#check_list'

  # Routes pour la création de réservations
  resources :reservations, only: [:new, :create]

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  # Defines the root path route ("/")
  root "static_pages#home"

  # routes pour la gestion de la comptabilité
  resources :transactions do
    get 'analytics', on: :collection
  end

  # routes pour la gestion des vols
  resources :vols, only: [:new, :create, :index, :show]

  # Route pour récupérer des informations sur les avions (ex: dernier compteur)
  resources :avions, only: [] do
    # Route pour le formulaire de signalement pour un avion spécifique
    resources :signalements, only: [:new, :create]

    member do
      get :last_compteur
    end
  end

  # Route pour la liste des signalements sur un avion
  resources :signalements, only: [:index, :show, :edit, :update, :destroy]

  # routes pour l'administration
  namespace :admin do
    resources :users, only: [:new, :create]
    # On ajoute les routes pour gérer les actualités (sauf la page "show" qui n'est pas utile ici)
    resources :news_items, except: [:show]
  end

  # routes pour les cours (à compléter avec les cours du club)
  resources :elearning, only: [:index, :show] do
    member do
      get 'document'
    end
  end
  resources :audios, only: [:show]

  # routes pour les événements, avec des routes imbriquées pour les participations
  # et une page de confirmation de suppression
  resources :events do
    resources :attendances, only: [:new, :create]
    member do
      get 'confirm_destroy'
    end
    delete 'delete_past', on: :collection # Ajoute la route DELETE /events/delete_past
    resources :attendances, only: [:create, :destroy]
    resources :comments, only: [:create, :edit, :update, :destroy]
  end

  # Stripe Checkout
  get 'checkout', to: 'checkout#show'
  post 'checkout', to: 'checkout#create'
  post 'stripe-webhooks', to: 'stripe_webhooks#create'

  # routes pour les pages statiques de la navbar
  get 'club', to: 'static_pages#club'
  get 'flotte', to: 'static_pages#flotte'
  get 'mediatheque', to: 'static_pages#mediatheque'
  get 'tarifs', to: 'static_pages#tarifs'
  get 'bia', to: 'static_pages#bia'
  get 'baptemes', to: 'static_pages#baptemes'
  get 'outils', to: 'static_pages#outils'
  resources :flight_lessons, only: [:index, :show]
  get 'documents_divers', to: 'static_pages#documents_divers'
  get 'credit', to: 'static_pages#credit'
  get 'agenda_avion', to: 'static_pages#agenda_avion'
  get 'agenda_instructeurs', to: 'static_pages#agenda_instructeurs'

  # routes pour les pages statiques du footer
  get 'contact', to: 'static_pages#contact' # Route pour afficher la page de contact
  post 'contact', to: 'static_pages#create_contact' # Route pour la soumission du formulaire
  get 'team', to: 'static_pages#team'
  get 'privacy_policy', to: 'static_pages#privacy_policy'

  # Route pour gérer le téléchargement des fichiers
  get 'download/:filename', to: 'static_pages#download', as: 'download_file', constraints: { filename: /[^\/]+/ }
  
  # --- Routes pour l'authentification Google Calendar ---
  namespace :google_auth do
    get 'redirect', to: 'authentication#redirect', as: 'redirect'
    get 'callback', to: 'authentication#callback', as: 'callback'
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
  
  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

end
