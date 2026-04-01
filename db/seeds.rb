# Production: set ADMIN_EMAIL and ADMIN_PASSWORD env vars before running db:seed
if ENV["ADMIN_EMAIL"].present? && ENV["ADMIN_PASSWORD"].present?
  unless User.exists?(email_address: ENV["ADMIN_EMAIL"])
    User.create!(email_address: ENV["ADMIN_EMAIL"], password: ENV["ADMIN_PASSWORD"], admin: true)
    puts "Admin user created: #{ENV["ADMIN_EMAIL"]}"
  end
end

# Development defaults
if Rails.env.development?
  unless User.exists?(email_address: "jj35717@naver.com")
    User.create!(email_address: "jj35717@naver.com", password: "!Tt7752378777523787", admin: true)
  end
end
