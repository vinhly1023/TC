Rails.application.routes.draw do
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

  get 'dashboard/index'
  get 'dashboard/refresh_env'
  get 'dashboard/env_versions'
  get 'dashboard/filter_results'

  get 'accounts/process_linking_devices'
  get 'accounts/children'
  get 'accounts/devices'
  get 'accounts/app_history'
  post 'accounts/unlink_devices'
  post 'accounts/update_customer'
  post 'accounts/revoke_license'
  get 'accounts/remove_license'
  get 'accounts/report_installation'

  post 'pins/pin_status'
  get 'pins/pin_status'

  post 'users/sign_in'
  get 'users/sign_in'
  get 'users/sign_out'
  get 'users/create'
  post 'users/create'
  post 'users/sign_up'
  post 'users/edit'
  get 'users/help'
  get 'users/download'

  post 'activity_tracking/update_limit'

  post 'atg_moas_importings/excel2mysql'
  get 'atg_moas_importings/index'
  get 'atg_content_platform_checker/index'
  post 'atg_content_platform_checker/validate_content_platform'

  get 'atgs/atg_tracking_data'
  get 'atgs/atg_configuration'
  get 'atgs/update_atg_data'
  get 'atgs/create_ts'
  get 'atgs/upload_code'
  get 'atgs/upload_server_url'
  post 'atgs/clean_pins'
  post 'atgs/upload_code'
  post 'atgs/upload_server_url'
  post 'atgs/upload_com_server'
  get 'atgs/upload_com_server'
  post 'atgs/upload_promotion_code'
  get 'atgs/upload_promotion_code'

  post 'rails_app_config/update_smtp_settings'

  get 'stations/index'
  post 'stations/update_machine_config'
  post 'stations/delete_station'
  get 'stations/station_list'

  post 'email_rollup/configure_rollup_email'

  post 'scheduler/update_scheduler_status'
  post 'scheduler/update_scheduler_location'
  post 'scheduler/update_scheduler'
  post 'scheduler/delete_scheduler'
  get 'scheduler/scheduler_list'

  post 'run/add_queue'
  get 'run/test_case_list'
  get 'run/status'

  get 'outpost/refresh'
  get 'outpost/file_content'
  post 'outpost/update_file'
  post 'outpost/update_limit_running'
  get 'outpost/test_suites'
  get 'outpost/controls'
  get 'outpost/release_date'

  root 'dashboard#index'

  match '/about', to: 'static_pages#about', via: 'get'
  match '/accessdeny', to: 'static_pages#accessdeny', via: 'get'

  match '/users/logging/p/:page', to: 'activity_tracking#logging', via: 'get'
  match '/users/logging/u/:user_id', to: 'activity_tracking#logging', via: 'get'
  match '/users/logging/u/:user_id/p/:page', to: 'activity_tracking#logging', via: 'get'
  match '/users/help/view_markdown/:file', to: 'users#view_markdown', via: 'get', constraints: { file: /.*/ }
  match '/users/logging', to: 'activity_tracking#logging', via: 'get'
  match '/users/logging', to: 'users#logging', via: 'get'
  match '/accessdeny', to: 'static_pages#accessdeny', via: 'get'

  match '/utilities/clear_account', to: 'accounts#clear_account', via: 'get'
  match '/utilities/customer_lookup', to: 'accounts#fetch_customer', via: 'get'
  match '/utilities/device_linking', to: 'accounts#link_devices', via: 'get'
  match '/utilities/device_lookup', to: 'device_lookup#index', via: 'get'
  match '/utilities/geoip_lookup', to: 'geoip_lookup#index', via: 'get'
  match '/utilities/redeem_pin', to: 'pins#redeem_pin', via: 'get'
  match '/utilities/pin_status', to: 'pins#pin_status', via: 'get'

  match '/atgs/ajax/atg_tracking_data', to: 'atgs#atg_tracking_data', via: 'get'
  match '/atgs/ajax/create_ts', to: 'atgs#create_ts', via: 'get'
  match '/atg/first_parent_level_tss', to: 'atgs#first_parent_level_tss', via: 'get'
  match '/atg/parent_suite_id', to: 'atgs#parent_suite_id', via: 'get'
  match '/atg/release_date', to: 'atgs#release_date', via: 'get'

  match '/web_services/back', to: 'web_services#back', via: 'get'

  match '/admin/rails/app_config', to: 'rails_app_config#configuration', via: 'get'
  match '/auto_config/update_run_queue_option', to: 'rails_app_config#update_run_queue_option', via: 'post'
  match '/auto_config/update_email_queue_setting', to: 'rails_app_config#update_email_queue_setting', via: 'post'

  match '/admin/scheduler', to: 'scheduler#index', via: 'get'
  match '/admin/email_rollup', to: 'email_rollup#index', via: 'get'
  match '/admin/stations', to: 'stations#index', via: 'get'
  match '/:silo_name/view:view_path', to: 'run#view_result', via: 'get', constraints: { view_path: /.*(.html)/ }
  match '/:silo_name/view/:date', to: 'run#view_silo_group', via: 'get', constraints: { date: /\d{4}-\d\d/ }
  match '/:silo_name/delete/:view_path', to: 'run#delete', via: 'get', constraints: { view_path: /.*/ }
  match '/:silo_name/download/:view_path', to: 'run#download', via: 'get', constraints: { view_path: /.*/ }
  match '/:silo_name/view:view_path', to: 'run#view_silo_group', via: 'get', constraints: { view_path: /.*/ }
  match '/run/show_view_silo/:silo_name/view', to: 'run#show_view_silo', via: 'get'
  match '/run/show_view_silo/:silo_name/view/:date', to: 'run#show_view_silo', via: 'get', constraints: { date: /\d{4}-\d\d/ }
  match '/run/show_view_silo/:silo_name/view/:view_path', to: 'run#show_view_silo', via: 'get', constraints: { view_path: /.*/ }

  match '/:silo_name/run', to: 'run#index', via: 'get'
  match '/:silo_name/run', to: 'run#index', via: 'post'
  match '/run/show_run_silo/:silo_name', to: 'run#show_run_silo', via: 'get'

  match '/tc/download_file/:file_path', to: 'run#download_file', via: 'get'
  match '/:silo_name/upload_result', to: 'outpost#upload_result', via: 'get'
  match '/:silo_name/upload_result', to: 'outpost#upload_result', via: 'post'
  match '/:silo_name/config', to: 'outpost#outpost_config', via: 'get'
  match '/:silo_name/config', to: 'outpost#outpost_config', via: 'post'
  match '/:silo_name/upload_pin', to: 'outpost#upload_pin', via: 'get'
  match '/:silo_name/upload_pin', to: 'outpost#upload_pin', via: 'post'
  match '/:silo_name/upload_moas', to: 'outpost#upload_moas', via: 'get'
  match '/:silo_name/upload_moas', to: 'outpost#upload_moas', via: 'post'
  match '/:silo_name/platform_checker', to: 'outpost#platform_checker', via: 'get'
  match '/:silo_name/platform_checker', to: 'outpost#platform_checker', via: 'post'
  match '/:silo_name/promotion_code', to: 'outpost#promotion_code', via: 'get'
  match '/:silo_name/promotion_code', to: 'outpost#promotion_code', via: 'post'
  match '/outpost/test_suite_instruction', to: 'outpost#test_suite_instruction', via: 'get'

  match '/search', to: 'search#index', via: 'get'
  match '/search', to: 'search#index', via: 'post'

  match '/view/daily:date', to: 'dashboard#daily', via: 'get', constraints: { date: /.*/ }

  match 'rest/v1/sso', to: 'rest/v1/api#sso', via: 'post'
  match 'rest/v1/upload_outpost_json_file', to: 'rest/v1/api#upload_outpost_json_file', via: 'post'
  match 'rest/v1/register', to: 'rest/v1/api#register', via: 'post'
  match 'rest/v1/email_queue', to: 'rest/v1/api#add_email_queue', via: 'post'
  match 'rest/v1/running_count', to: 'rest/v1/api#update_outpost_running_count', via: 'put'

  match '/outpost/delete', to: 'dashboard#delete_outpost', via: 'post'
  match '/auto_config/update_outpost_settings', to: 'rails_app_config#update_outpost_settings', via: 'post'
end
