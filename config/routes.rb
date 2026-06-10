Rails.application.routes.draw do
  # Developer auth (Devise + GitHub OmniAuth)
  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks" }

  # Collaborator portal — unauthenticated entry point
  scope "/p/:share_token" do
    get  "/",        to: "portal#show",         as: :portal
    post "/sessions", to: "portal/sessions#create", as: :portal_sessions
    delete "/sessions", to: "portal/sessions#destroy", as: :portal_session
    get  "/sessions/new", to: "portal/sessions#new", as: :new_portal_session
    get  "/sessions/verify", to: "portal/sessions#verify", as: :verify_portal_session
    get  "/submissions", to: "portal/submissions#index", as: :portal_submissions
    post "/submissions", to: "portal/submissions#create"
    get  "/submissions/new", to: "portal/submissions#new", as: :new_portal_submission
    get  "/submissions/:id/refine", to: "portal/refinements#show", as: :portal_submission_refine
    post "/submissions/:id/refine/messages", to: "portal/refinements#create_message", as: :portal_submission_refine_messages
    post "/submissions/:id/refine/finalize", to: "portal/refinements#finalize", as: :portal_submission_refine_finalize
    patch "/profile", to: "portal/profile#update", as: :portal_profile
    get   "/profile/edit", to: "portal/profile#edit", as: :edit_portal_profile
  end

  # Developer dashboard
  resources :projects do
    collection do
      get :github_repos
    end
    resources :submissions, only: %i[index show] do
      member do
        post :accept
        post :dismiss
        post :ship
      end
    end
    member do
      post :rotate_token
    end
  end

  get "/dashboard", to: "dashboard#index", as: :dashboard

  namespace :admin do
    root to: "dashboard#index"
  end

  root to: "home#index"

  get "up" => "rails/health#show", as: :rails_health_check
  get "manifest.json", to: "pwa#manifest", as: :pwa_manifest

  authenticate :user do
    mount GoodJob::Engine => "/jobs"
  end
end
