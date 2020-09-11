require "sidekiq/web"

Rails.application.routes.draw do
  devise_for :users, controllers: {omniauth_callbacks: "users/omniauth_callbacks",
                                   sessions: "users/sessions",
                                   registrations: "users/registrations"}

  root "landing#index"

  resources :citations
  resources :assertions

  authenticate :user, lambda { |u| u.developer? } do
    mount Sidekiq::Web, at: "/sidekiq"
  end

  resource :account, only: %i[show edit update]
end
