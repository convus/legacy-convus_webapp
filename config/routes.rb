require "sidekiq/web"

Rails.application.routes.draw do
  devise_for :users, controllers: {omniauth_callbacks: "users/omniauth_callbacks"}

  devise_scope :user do
    get "users/sign_out" => "devise/sessions#destroy"
  end

  root "hypotheses#index"

  resource :account, only: %i[show edit update]

  get :about, to: "static#about"
  get :citation_scoring, to: "static#citation_scoring"

  resources :citations, :publications, :hypotheses

  resources :user_scores, only: [:create]

  get "/citations/:publication_id/:citation_id", to: "citations#show"

  post "/webhooks/github", to: "webhooks#github"

  namespace :admin do
    root to: "content_commits#index"
    resources :content_commits
  end

  authenticate :user, lambda { |u| u.developer? } do
    mount Sidekiq::Web, at: "/sidekiq"
  end
end
