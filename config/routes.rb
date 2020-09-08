require "sidekiq/web"

Rails.application.routes.draw do
  # devise_for :users, controllers: {omniauth_callbacks: "users/omniauth_callbacks",
  #                                  sessions: "users/sessions",
  #                                  registrations: "users/registrations"}

  root "landing#index"
end
