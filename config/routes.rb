Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  post "uploads/chunk", to: "uploads#chunk", as: :upload_chunk

  get  "compress",         to: "compress#new",   as: :new_compress
  post "compress/start",   to: "compress#start", as: :start_compress

  get  "resize",         to: "resize#new",   as: :new_resize
  post "resize/start",   to: "resize#start", as: :start_resize

  get  "convert",       to: "convert#new",   as: :new_convert
  post "convert/start", to: "convert#start", as: :start_convert

  get "jpg-to-png",  to: "convert#new", defaults: { from_format: "jpg",  to_format: "png"  }, as: :jpg_to_png
  get "jpg-to-webp", to: "convert#new", defaults: { from_format: "jpg",  to_format: "webp" }, as: :jpg_to_webp
  get "png-to-jpg",  to: "convert#new", defaults: { from_format: "png",  to_format: "jpeg" }, as: :png_to_jpg
  get "png-to-webp", to: "convert#new", defaults: { from_format: "png",  to_format: "webp" }, as: :png_to_webp
  get "webp-to-jpg", to: "convert#new", defaults: { from_format: "webp", to_format: "jpeg" }, as: :webp_to_jpg
  get "webp-to-png", to: "convert#new", defaults: { from_format: "webp", to_format: "png"  }, as: :webp_to_png

  get  "download/:task_id",         to: "downloads#show", as: :download
  get  "download/:task_id/zip",     to: "downloads#zip",  as: :download_zip

  root "pages#home"
end
