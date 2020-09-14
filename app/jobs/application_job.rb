# Using activejob is slow. Just use sidekiq
# ActiveJob is included to make actionmailer work with delayed, and maybe other things
# ... But all the jobs are sidekiq only
class ApplicationJob
  include Sidekiq::Worker
end
