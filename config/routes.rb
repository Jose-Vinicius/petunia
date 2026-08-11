Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # User authentication routes
  devise_for :users

  # Account management, switching, and member management routes
  resources :accounts, only: [ :index, :new, :create ] do
    post :switch, on: :member
    resources :account_users, only: [ :index, :create, :destroy ], path: "members"
  end

  # Financial entities: Bank Accounts, Credit Cards, Categories, Cost Centers, Suppliers & Transactions
  resources :bank_accounts, except: [ :show ]
  resources :credit_cards, except: [ :show ]
  resources :categories, except: [ :show ]
  resources :cost_centers, except: [ :show ]
  resources :suppliers, except: [ :show ]
  resources :transactions, except: [ :show ]

  # Dashboard & Spreadsheet Import
  get "dashboard" => "dashboard#index", as: :dashboard
  resources :imports, only: [ :new, :create ] do
    post :preview, on: :collection
    get :download_template, on: :collection
  end


  # Defines the root path route ("/")
  root "home#index"
end
