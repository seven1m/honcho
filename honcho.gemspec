Gem::Specification.new do |gem|
  gem.name          = 'honcho'
  gem.authors       = ['Tim Morgn']
  gem.email         = ['tim@timmorgan.org']
  gem.summary       = 'Sidekiq- and Resque-aware process manager (alternative to Foreman)'
  gem.description   = 'Sidekiq- and Resque-aware process manager (alternative to Foreman)'
  gem.homepage      = 'https://github.com/seven1m/honcho'
  gem.license       = 'MIT'
  gem.executables   = ['honcho']
  gem.files         = Dir['bin/*', 'lib/**/*'].to_a
  gem.require_paths = ['lib']
  gem.version       = '1.0.1'
  gem.add_dependency 'redis'
end
