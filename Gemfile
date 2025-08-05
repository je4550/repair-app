source "https://rubygems.org"

ruby "3.3.8"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.0.2"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"
# Use sqlite3 as the database for Active Record in development
gem "sqlite3", ">= 2.1", group: [:development, :test]

# Use PostgreSQL for staging and production
gem "pg", "~> 1.5", group: [:staging, :production]
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
gem "bcrypt", "~> 3.1.7"

# Authentication
gem "devise", "~> 4.9"

# Authorization
gem "pundit", "~> 2.3"

# Background jobs
gem "sidekiq", "~> 7.3"

# Redis for caching and ActionCable in production
gem "redis", ">= 4.0.1"

# Pagination
gem "pagy", "~> 9.0"

# Form handling
gem "simple_form", "~> 5.3"

# Phone number validation
gem "phonelib", "~> 0.9"

# State machines
gem "aasm", "~> 5.5"

# Soft deletes
gem "paranoia", "~> 3.0"

# For handling money
gem "money-rails", "~> 1.15"

# For VIN decoding
gem "vin_exploder", "~> 0.5"

# SMS functionality (we'll configure later)
# gem "twilio-ruby", "~> 7.3"

# Email service (we'll configure later)
# gem "sendgrid-ruby", "~> 6.7"

# File uploads
gem "image_processing", "~> 1.2"

# API serialization
gem "jsonapi-serializer", "~> 2.2"

# Multi-tenancy
gem "acts_as_tenant", "~> 1.0"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
# Only in development/test - production uses Redis
gem "solid_cache", group: [:development, :test]
gem "solid_queue", group: [:development, :test]
gem "solid_cable", group: [:development, :test]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false
  
  # Testing framework
  gem "rspec-rails", "~> 7.0"
  gem "factory_bot_rails", "~> 6.4"
  gem "faker", "~> 3.4"
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"
end
