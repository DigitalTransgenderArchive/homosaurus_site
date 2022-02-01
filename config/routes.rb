Rails.application.routes.draw do
  devise_for :users

  #get 'search/index'
  get 'search/:id' => 'vocabulary#search', as: :vocabulary_search_results
  get 'tree' => 'graph#tree', as: :tree
  get 'tree_data' => 'graph#tree_data', as: :tree_data
  get ':id' => 'vocabulary#index', as: :vocabulary_index
  get ':vocab_id/:id' => 'vocabulary#show', as: :vocabulary_show

  #resources :vocabs_v3, only: [:index, :show], :path => '/v3'

  #resources :vocabs_v2, only: [:index, :show], :path => '/v2'

  #resources :vocabs, only: [:index, :show], :path => :terms


  root to: 'homepage#index'
  get 'releases' => 'homepage#release', as: :release
  get 'about' => 'homepage#about', as: :about
  post 'about' => 'homepage#about', as: :reveal_emails
  get 'contact' => 'homepage#contact', as: :contact
  post 'contact' => 'homepage#contact'
  get 'feedback_complete' => 'homepage#feedback_complete', as: :feedback_complete


  #get 'search/terms' => 'search#index', as: :search_results
  #get 'search/v2' => 'search_v2#index', as: :search_results_v2
  #get 'search/v3' => 'search_v3#index', as: :search_results_v3

  get 'indented_tree' => 'graph#indented_tree', as: :indented_tree

  #get 'search' => 'search_v2#index', as: :search_results_v2, :path => '/v2/search'
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
