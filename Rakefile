
require 'rspec/core/rake_task'
require 'yard'

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
end

YARD::Rake::YardocTask.new do |t|
  t.files   = ['lib/**/*.rb']                # optional
  t.stats_options = ['--list-undoc']         # optional
end

task :default  => :spec
