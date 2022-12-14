Rails.application.routes.draw do
  # routes for Hist
  mount Hist::Engine => '/hist'

  devise_for :users
  mount Hydra::RoleManagement::Engine => '/'

  #get 'search/index'
  get 'search/:id' => 'vocabulary#search', as: :vocabulary_search_results
  get 'tree' => 'graph#tree', as: :tree
  get 'tree_data' => 'graph#tree_data', as: :tree_data
  get 'indented_tree' => 'graph#indented_tree', as: :indented_tree

  get 'about' => 'homepage#about', as: :about
  post 'about' => 'homepage#about', as: :reveal_emails
  get 'contact' => 'homepage#contact', as: :contact
  post 'contact' => 'homepage#contact'
  get 'feedback_complete' => 'homepage#feedback_complete', as: :feedback_complete

  # releases
  get 'releases' => 'release#index', as: :release
  get 'releases/show/:release_id' => 'release#show', as: :release_show

  # Archives releases
  get 'releases/archive/release_notes_2_1' => 'release#release_notes_2_1', as: :archive_release_2_1
  get 'releases/archive/release_notes_2_2' => 'release#release_notes_2_2', as: :archive_release_2_2
  get 'releases/archive/release_notes_2_3' => 'release#release_notes_2_3', as: :archive_release_2_3
  get 'releases/archive/release_notes_3_0' => 'release#release_notes_3_0', as: :archive_release_3_0
  get 'releases/archive/release_notes_3_1' => 'release#release_notes_3_1', as: :archive_release_3_1
  get 'releases/archive/release_notes_3_2' => 'release#release_notes_3_2', as: :archive_release_3_2

  # Autocomplete Routes
  get '/autocomplete/exact_match_lcsh', to: "autocomplete#lcsh_subject", as: :exact_match_lcsh_autocomplete
  get '/autocomplete/close_match_lcsh', to: "autocomplete#lcsh_subject", as: :close_match_lcsh_autocomplete
  get '/autocomplete/languages', to: "autocomplete#languages", as: :languages_autocomplete

  # Admin Routes
  get '/admin/version/new' => 'admin#version_new', as: :version_publish_new
  post '/admin/version/publish' => 'admin#version_create', as: :version_publish_create

  # These should be next to last
  get ':vocab_id/new_term' => 'vocabulary#new', as: :vocabulary_term_new
  post ':vocab_id/new_term' => 'vocabulary#create', as: :vocabulary_term_create
  get ':vocab_id/:id/edit' => 'vocabulary#edit', as: :vocabulary_term_edit
  patch ':vocab_id/:id/update' => 'vocabulary#update', as: :vocabulary_term_update
  #patch ':vocab_id/:id/update_immediate' => 'vocabulary#update_immediate', as: :vocabulary_term_update_immediate
  delete ':vocab_id/:id/delete' => 'vocabulary#destroy', as: :vocabulary_term_delete
  delete ':vocab_id/:id/delete_version' => 'vocabulary#destroy_version', as: :vocabulary_term_delete_version
  get ':vocab_id/:id/restore' => 'vocabulary#restore', as: :vocabulary_term_restore
  get ':vocab_id/:id/replace/:replacement_id' => 'vocabulary#replace', as: :replace

  # These have to be last
  get ':id' => 'vocabulary#index', as: :vocabulary_index
  get ':vocab_id/:id' => 'vocabulary#show', as: :vocabulary_show


  #resources :vocabs_v3, only: [:index, :show], :path => '/v3'

  #resources :vocabs_v2, only: [:index, :show], :path => '/v2'

  #resources :vocabs, only: [:index, :show], :path => :terms


  root to: 'homepage#index'


  #get 'search/terms' => 'search#index', as: :search_results
  #get 'search/v2' => 'search_v2#index', as: :search_results_v2
  #get 'search/v3' => 'search_v3#index', as: :search_results_v3

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
