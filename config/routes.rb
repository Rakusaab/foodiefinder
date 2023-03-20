Rails.application.routes.draw do
  root 'restaurants#index'
  devise_for :users do
      get '/users/sign_out' => 'devise/sessions#destroy'
  end
  resources :urls
  resources :restaurants, only: [:index, :show]
  get 'restaurants/search', to: 'restaurants#search', as: 'search_restaurants'
end 