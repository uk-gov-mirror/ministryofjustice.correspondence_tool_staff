# Load the Rails application.
require_relative 'application'

# Use a real queuing backend for Active Job (and separate queues per
# environment so that we don't conflict with public tool say, for example, on
# our local dev boxes)
Rails.configuration.active_job.queue_adapter     = :sidekiq
Rails.configuration.active_job.queue_name_prefix = "correspondence_tool_staff_#{Rails.env}"

# Initialize the Rails application.
Rails.application.initialize!
