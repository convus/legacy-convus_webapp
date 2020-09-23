require "sidekiq/web"

Rails.application.routes.draw do
  devise_for :users, controllers: {omniauth_callbacks: "users/omniauth_callbacks",
                                   sessions: "users/sessions",
                                   registrations: "users/registrations"}

  root "hypotheses#index"

  get :about, to: "landing#about"

  resources :citations, :publications, :hypotheses

  get "/citations/:publication_id/:citation_id", to: "citations#show"

  authenticate :user, lambda { |u| u.developer? } do
    mount Sidekiq::Web, at: "/sidekiq"
  end

  resource :account, only: %i[show edit update]
end
