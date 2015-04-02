
require 'rspec/core/rake_task'
require 'yard'

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.exclude_pattern = 'spec/integration_tests/**/*_spec.rb'
end


# Larger integration/acceptance style tests (take several minutes to complete)
RSpec::Core::RakeTask.new(:integration_tests) do |spec|
  spec.pattern = 'spec/integration_tests/**/*_spec.rb'
end


YARD::Rake::YardocTask.new(:yard) do |t|
  t.files   = ['lib/**/*.rb']                # optional
  t.stats_options = ['--list-undoc']         # optional
end

task :default  => :spec     # Default task is to just run shorter (unit) tests
