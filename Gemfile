source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "2.7.1"

# Basic stuff
gem "rails", "~> 6.0.3", ">= 6.0.3.2"
# Use postgresql as the database for Active Record
gem "pg", ">= 0.18", "< 2.0"
# Use Puma as the app server
gem "puma", "~> 4.1"

# Authentication stuff
gem "devise" # Authentication
gem "omniauth", "~> 1.6.1" # sign on with other services
gem "omniauth-github", github: "omniauth/omniauth-github", branch: "master"

# Frontend stuff
gem "sass-rails", ">= 6" # SCSS for stylesheets
# Transpile app-like JavaScript. Read more: https://github.com/rails/webpacker
gem "webpacker", "~> 4.0"
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem "turbolinks", "~> 5"
gem "hamlit" # Faster haml templates

# Redis stuff
gem "hiredis"
gem "redis", require: ["redis", "redis/connection/hiredis"]
gem "sidekiq" # Background processing, uses redis, in lieu of activeJob
gem "sidekiq-failures" # See background job failures

# logging stuff - make it more useful and ingestible
gem "lograge" # Structure log data, put it in single lines to improve the functionality
gem "logstash-event" # Use logstash format for logging data

# API stuff
# More recent versions of active_model_serializers have gotten slower, so use fastest version
gem "active_model_serializers", "~> 0.8.3" # Serialize things

# Other app stuff
gem "kaminari" # Pagination

group :production do
  gem "honeybadger" # Error monitoring
end

group :development, :test do
  gem "dotenv-rails" # Environmental variables, not used in production
  gem "rspec" # Testing
  gem "rspec-rails"
  gem "standard" # Ruby linter
  gem "factory_bot_rails"
end

group :development do
  gem "foreman" # Process runner
  gem "rerun" # Restart server when files change
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  # gem 'web-console', '>= 3.3.0'
  gem "listen", "~> 3.2"
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem "spring"
  gem "spring-watcher-listen", "~> 2.0.0"
end

group :test do
  gem "rails-controller-testing"
  gem "guard", require: false
  gem "guard-rspec", require: false
  gem "rspec_junit_formatter" # For circle ci
  gem "vcr" # Stub external HTTP requests
  gem "webmock" # mocking for VCR
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]

# Performance Stuff
gem "fast_blank" # high performance replacement String#blank? a method that is called quite frequently in ActiveRecord
gem "flamegraph", require: false
gem "stackprof", require: false # Required by flamegraph
gem "rack-mini-profiler", require: false # If you can't see it you can't make it better
gem "memory_profiler"
gem "bootsnap", ">= 1.1.0", require: false # Reduces boot times through caching; required in config/boot.rb
