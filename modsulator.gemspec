version = File.read("VERSION").strip

Gem::Specification.new do |s|
  s.name        =  'modsulator'
  s.version     =  version
  s.summary     =  "Produces (Stanford) MODS XML from spreadsheets."
  s.description =  "Tools and libraries for working with metadata spreadsheets and MODS."
  s.authors     =  ["Tommy Ingulfsen"]
  s.email       =  'tommyi@stanford.edu'
  s.files       =  Dir["{lib}/**/*", "Rakefile", "README.md", "LICENSE"]
  s.test_files  =  Dir["spec/**/*"]
  s.homepage    =  'https://github.com/sul-dlss/modsulator'
  s.license     =  'Apache-2.0'
  s.platform    =  Gem::Platform::RUBY
  s.executables << 'modsulator'

  s.add_dependency 'roo', '>= 1.1'
  s.add_dependency 'equivalent-xml', '>= 0.6.0'   # For ignoring_attr_values() with arguments
  s.add_dependency 'nokogiri'
  s.add_dependency 'activesupport'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec', '>= 3.0'
  s.add_development_dependency 'yard'
  s.add_development_dependency 'coveralls'
  s.add_development_dependency 'ruby-lint'
end
