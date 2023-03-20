Rails.application.routes.draw do
  root 'restaurants#index'

  resources :restaurants, only: [:index, :show]
  get 'restaurants/search', to: 'restaurants#search', as: 'search_restaurants'
end