Gem::Specification.new do |s|
  s.name        =  'MODSulator'
  s.version     =  '0.0.0'
  s.summary     =  "Produces (Stanford) MODS XML from spreadsheets."
  s.description =  "Tools and libraries for working with metadata spreadsheets and MODS."
  s.authors     =  ["Tommy Ingulfsen"]
  s.email       =  'tommyi@stanford.edu'
  s.files       =  Dir["{lib}/**/*", "Rakefile", "README.md", "LICENSE"]
  s.test_files  =  Dir["spec/**/*"]
  s.homepage    =  'https://github.com/sul-dlss/modsulator'
  s.license     =  'Apache-2.0'
  s.platform    =  Gem::Platform.local
  s.executables << 'modsulator'

  s.add_dependency 'roo', '~> 1.1'
  s.add_dependency 'rspec', '~> 3.0'
  s.add_dependency 'activesupport', '~> 3.0'   # For ActiveSupport::HashWithIndifferentAccess
end
