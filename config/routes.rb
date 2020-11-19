require "sidekiq/web"

Rails.application.routes.draw do
  devise_for :users, controllers: {omniauth_callbacks: "users/omniauth_callbacks"}

  devise_scope :user do
    get "users/sign_out" => "devise/sessions#destroy"
  end

  root "hypotheses#index"

  get :about, to: "landing#about"

  resources :citations, :publications, :hypotheses

  resources :user_scores, only: [:create]

  get "/citations/:publication_id/:citation_id", to: "citations#show"


  match "/webhooks/reconcile_content", to: "webhooks#reconcile_content", via: :all

  authenticate :user, lambda { |u| u.developer? } do
    mount Sidekiq::Web, at: "/sidekiq"
  end

  resource :account, only: %i[show edit update]
end
