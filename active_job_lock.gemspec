$:.push File.expand_path("../lib", __FILE__)
require 'active_job_lock/version'

Gem::Specification.new do |s|
  s.name              = 'active_job_lock'
  s.version           = ActiveJobLock::VERSION
  s.date              = Time.now.strftime('%Y-%m-%d')
  s.summary           = 'An ActiveJob plugin to add locking, with optional timeout/deadlock handling.'
  s.license           = 'MIT'
  s.homepage          = 'http://github.com/dferrazm/active_job_lock'
  s.email             = ''
  s.authors           = ['Daniel Ferraz', 'Luke Antins']
  s.has_rdoc          = false

  s.files             = %w(README.md Rakefile LICENSE HISTORY.md)
  s.files            += Dir.glob('lib/**/*')
  s.files            += Dir.glob('test/**/*')

  s.add_dependency('resque', '~> 1.22')
  s.add_development_dependency('rake', '~> 10.3')
  s.add_development_dependency('minitest', '~> 5.2')
  s.add_development_dependency('yard', '~> 0.8')
  s.add_development_dependency('simplecov', '~> 0.7', '>= 0.7.1')

  s.description       = <<desc
  An ActiveJob plugin. Adds locking, with optional timeout/deadlock handling.

  Using a `lock_timeout` allows you to re-acquire the lock should your job
  fail, crash, or is otherwise unable to relase the lock.

  i.e. Your server unexpectedly looses power. Very handy for jobs that are
  recurring or may be retried.
desc
end
