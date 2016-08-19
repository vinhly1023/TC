#!/usr/bin/env puma
environment(ENV['RAILS_ENV'] || 'production')
daemonize false
pidfile 'tmp/puma.pid'

threads 1, 16
bind 'tcp://127.0.0.1:9292'

# Close any connections to the database here to prevent connection leakage:
before_fork do
  ActiveRecord::Base.connection_pool.disconnect!
end
