Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  constraints subdomain: "admin" do
    resource :session
    resource :password, only: [ :new, :edit, :update ]

    scope module: :admin, as: :admin do
      root "dashboard#index"
      resources :posts
      resources :uploads, only: [ :index, :create ]
      get  "ai-writer",          to: "ai_writer#index",    as: :ai_writer
      post "ai-writer/generate", to: "ai_writer#generate", as: :ai_writer_generate
    end
  end
  get "sitemap.xml", to: "sitemaps#show"

  # Paddle webhook
  post "webhooks/paddle", to: "paddle_webhooks#receive", as: :paddle_webhook

  # API endpoints — no locale prefix needed
  post "uploads/chunk",  to: "uploads#chunk",  as: :upload_chunk
  post "compress/start", to: "compress#start", as: :start_compress
  post "resize/start",   to: "resize#start",   as: :start_resize
  post "convert/start",  to: "convert#start",  as: :start_convert
  post "exif/start",     to: "exif#start",     as: :start_exif
  post "rotate/start",   to: "rotate#start",   as: :start_rotate
  post "crop/start",     to: "crop#start",     as: :start_crop

  # Download routes (no locale prefix — task_id is the identifier)
  get "download/:task_id",     to: "downloads#show", as: :download
  get "download/:task_id/zip", to: "downloads#zip",  as: :download_zip

  # Subscription
  post "subscription/checkout_complete", to: "subscriptions#checkout_complete", as: :subscription_checkout_complete
  post "subscription/sync",             to: "subscriptions#sync",             as: :subscription_sync
  get  "subscription/portal",           to: "subscriptions#portal",           as: :subscription_portal

  # Auth routes
  get    "/login",                         to: "auth#login",           as: :login
  get    "/auth/google_oauth2/callback",   to: "auth#google_callback"
  post   "/auth/failure",                  to: "auth#failure"
  delete "/logout",                        to: "auth#destroy",         as: :logout

  # Localized page routes
  scope "(:locale)", locale: PUBLIC_LOCALE_PATTERN do
    resources :posts, only: [ :index, :show ], param: :slug

    get "compress", to: "compress#new", as: :new_compress
    get "resize",   to: "resize#new",   as: :new_resize
    get "convert",  to: "convert#new",  as: :new_convert

    get "jpg-to-png",  to: "convert#new", defaults: { from_format: "jpg",  to_format: "png"  }, as: :jpg_to_png
    get "jpg-to-webp", to: "convert#new", defaults: { from_format: "jpg",  to_format: "webp" }, as: :jpg_to_webp
    get "png-to-jpg",  to: "convert#new", defaults: { from_format: "png",  to_format: "jpeg" }, as: :png_to_jpg
    get "png-to-webp", to: "convert#new", defaults: { from_format: "png",  to_format: "webp" }, as: :png_to_webp
    get "webp-to-jpg", to: "convert#new", defaults: { from_format: "webp", to_format: "jpeg" }, as: :webp_to_jpg
    get "webp-to-png", to: "convert#new", defaults: { from_format: "webp", to_format: "png"  }, as: :webp_to_png

    get "exif",   to: "exif#new",   as: :new_exif
    get "rotate", to: "rotate#new", as: :new_rotate
    get "crop",   to: "crop#new",   as: :new_crop

    get    "my-page", to: "pages#my_page",        as: :my_page
    delete "my-page", to: "pages#destroy_account", as: :destroy_account
    get "pricing", to: "pages#pricing", as: :pricing
    get "faq",     to: "pages#faq",     as: :faq
    get "terms",   to: "pages#terms",   as: :terms
    get "privacy", to: "pages#privacy", as: :privacy

    root "pages#home"
  end
end
