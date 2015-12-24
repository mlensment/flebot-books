Gem::Specification.new do |s|
  s.name        = 'flebot-books'
  s.version     = '0.0.0'
  s.date        = '2015-12-24'
  s.summary     = "Books app for Flebot"
  s.description = "Books app for Flebot"
  s.authors     = ["Martin Lensment"]
  s.email       = 'mlensment@gmail.com'
  s.files       = ["lib/flebot/books.rb"]
  s.homepage    = 'https://github.com/mlensment/flebot-books'
  s.license     = 'MIT'
  s.add_dependency 'sqlite3', '1.3.11'
  s.add_development_dependency 'rspec', '3.4'
end
