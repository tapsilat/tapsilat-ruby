require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'
require 'yard'

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new(:rubocop)
YARD::Rake::YardocTask.new(:yard)

task :console do
  require 'irb'
  require 'tapsilat'
  ARGV.clear
  IRB.start
end

task default: %i[spec rubocop]

desc 'Run all tests and linting'
task ci: %i[spec rubocop]

desc 'Generate test coverage report'
task :coverage do
  ENV['COVERAGE'] = 'true'
  Rake::Task[:spec].execute
end
