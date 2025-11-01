Rails.application.routes.draw do

  # Configuration de Devise :
  # On désactive la création de compte publique (gérée par l'admin).
  # On regroupe les routes de Devise ici pour éviter les conflits.
  devise_for :users, 
    skip: [:registrations], # On désactive les routes d'inscription publiques
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


  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  # Defines the root path route ("/")
  root "static_pages#home"

  # routes pour la gestion de la comptabilité
  resources :transactions do
    get 'analytics', on: :collection
  end

  # routes pour l'administration
  namespace :admin do
    resources :users, only: [:new, :create]
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
    resources :attendances, only: [:create, :destroy]
  end

  # routes pour les utilisateurs (profils, etc.) avec une route imbriquée pour les avatars
  resources :users, only: [:show, :edit, :update], constraints: { id: /\d+/ } do
    resources :avatars, only: [:create]
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
  # resources :cours_theoriques, to: 'elearning#index', as: 'cours_theoriques'
  resources :flight_lessons, only: [:index, :show]
  get 'documents_divers', to: 'static_pages#documents_divers'
  get 'credit', to: 'static_pages#credit'
  get 'agenda_avion', to: 'static_pages#agenda_avion'
  get 'agenda_instructeurs', to: 'static_pages#agenda_instructeurs'

  # routes pour les pages statiques du footer
  get 'faq', to: 'static_pages#faq'
  get 'contact', to: 'static_pages#contact'
  post 'contact', to: 'static_pages#create_contact' # Ajout de la route pour la soumission du formulaire
  get 'team', to: 'static_pages#team'
  get 'privacy_policy', to: 'static_pages#privacy_policy'

  # Route pour gérer le téléchargement des fichiers
  get 'download/:filename', to: 'static_pages#download', as: 'download_file', constraints: { filename: /[^\/]+/ }
  
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

end
