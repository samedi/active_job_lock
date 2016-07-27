require 'rake/testtask'
require 'yard'
require 'yard/rake/yardoc_task'
require 'bundler/gem_tasks'

task :default => :test

desc 'Run unit tests.'
Rake::TestTask.new(:test) do |task|
  task.test_files = FileList['test/*_test.rb']
  task.verbose = true
end

desc 'Build Yardoc documentation.'
YARD::Rake::YardocTask.new :yardoc do |t|
    t.files   = ['lib/**/*.rb']
    t.options = ['--output-dir', 'doc/',
                 '--files', 'LICENSE,HISTORY.md',
                 '--readme', 'README.md',
                 '--title', 'active_job_lock documentation']
end
