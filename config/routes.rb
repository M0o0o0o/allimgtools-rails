Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  post "uploads/chunk", to: "uploads#chunk", as: :upload_chunk

  get  "compress",                  to: "compress#new",   as: :new_compress
  get  "compress/:task_id",         to: "compress#show",  as: :compress
  post "compress/:task_id/start",   to: "compress#start", as: :start_compress

  get  "resize",                    to: "resize#new",     as: :new_resize
  get  "resize/:task_id",           to: "resize#show",    as: :resize
  post "resize/:task_id/start",     to: "resize#start",   as: :start_resize

  get  "download/:task_id",         to: "downloads#show", as: :download
  get  "download/:task_id/zip",     to: "downloads#zip",  as: :download_zip

  root "pages#home"
end
