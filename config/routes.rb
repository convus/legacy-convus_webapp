require "sidekiq/web"

Rails.application.routes.draw do
  devise_for :users, controllers: {omniauth_callbacks: "users/omniauth_callbacks"}

  devise_scope :user do
    get "users/sign_out" => "devise/sessions#destroy"
  end

  root "hypotheses#index"

  resource :account, only: %i[show edit update]

  get :about, to: "landing#about"

  resources :citations, :publications, :hypotheses

  resources :user_scores, only: [:create]

  get "/citations/:publication_id/:citation_id", to: "citations#show"

  # somehow, this comes in as a get (it should be a post), just let it happen
  match "/webhooks/github", to: "webhooks#github", via: :all

  namespace :admin do
    root to: "users#index"
    resources :content_commits
  end

  authenticate :user, lambda { |u| u.developer? } do
    mount Sidekiq::Web, at: "/sidekiq"
  end
end
