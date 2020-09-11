require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_mailbox/engine"
require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
require "sprockets/railtie"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Convus
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0

    # Set default timezone
    config.time_zone = "America/Los_Angeles" # Also set in TimeParser::DEFAULT_TIMEZONE

    # Use sidekiq because it's awesome
    config.active_job.queue_adapter = :sidekiq

    # Don't require all associations by default
    config.active_record.belongs_to_required_by_default = false

    config.generators do |g|
      g.factory_bot true
    end
  end
end
