# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users, controllers: {
    omniauth_callbacks: 'users/omniauth_callbacks',
    sessions: 'users/sessions'
  }

  match '/404', to: 'error#not_found', via: :all
  match '/422', to: 'error#unacceptable', via: :all
  match '/500', to: 'error#internal_error', via: :all

  post '/update-locale', to: 'users#update_locale', as: 'user_update_locale'

  resources :users do
    post :become, on: :member
  end

  resources :projects do
    resources :invoice_statuses, only: [] do
      post :confirm_hours, on: :member
    end

    get :onboarding, on: :member
    post :update_rate_from_onboarding, on: :member
    get :onboarding_invite_members, on: :member
    post :invite_member_from_onboarding, on: :member
    get :onboarding_done, on: :member

    get :status_period, on: :member

    resources :reports
    resources :project_contracts, except: [:index]

    resources :activity_tracks, except: [:index]
    resources :activity_stop_watches, except: [:index] do
      post :stop, on: :member
      post :resume, on: :member
      post :destroy, on: :member
      post :finish, on: :member
    end

    resources :invoices do
      post :add_entries_to_client_invoice, on: :member
      post :make_internal, on: :member
      post :make_client, on: :member
      post :email_notify, on: :member
      post :make_visible, on: :member
      post :hide, on: :member
      post :upload_invoice, on: :member
      post :upload_payment, on: :member
      get :download_invoice, on: :member
      get :download_payment, on: :member
      get :review_entries, on: :member
      get :status, on: :member
    end
  end

  resources :feedback_options, only: [:index]
  resources :submissions, only: [:create]
  resources :other_submissions, only: [:create]

  scope 'slack' do
    post 'log', to: 'slack#log'
  end

  get '/', to: 'home#index', as: 'home'
  get '/settings', to: 'home#settings', as: 'settings'
  get '/subscription', to: 'home#subscription', as: 'subscription'
  get '/solutions', to: 'home#solutions', as: 'home_solutions'
  get '/robots.:format', to: 'pages#robots'
  get '/sitemap.:format', to: 'pages#sitemap'
  root to: redirect('/')
end
