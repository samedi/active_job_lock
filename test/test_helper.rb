require 'minitest/pride'
require 'minitest/autorun'

require 'redis'
require 'active_job'
require 'active_job_lock'
require_relative 'test_jobs'

# make sure we can run redis-server
if !system('which redis-server')
  puts '', "** `redis-server` was not found in your PATH"
  abort ''
end

# make sure we can shutdown the server using cli.
if !system('which redis-cli')
  puts '', "** `redis-cli` was not found in your PATH"
  abort ''
end

puts "Starting redis for testing at localhost:6379..."

# Start redis server for testing.
`redis-server ./redis-test.conf`
ActiveJobLock::Config.redis = Redis.new(host: '127.0.0.1', port: '6379')

# After tests are complete, make sure we shutdown redis.
Minitest.after_run {
  `redis-cli -p 9737 shutdown nosave`
}
