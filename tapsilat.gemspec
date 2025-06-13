require_relative 'lib/tapsilat/version'

Gem::Specification.new do |spec|
  spec.name          = 'tapsilat'
  spec.version       = Tapsilat::VERSION
  spec.authors       = ['Tapsilat']
  spec.email         = ['support@tapsilat.com']

  spec.summary       = 'Ruby client for Tapsilat API'
  spec.description   = 'A simple Ruby client for interacting with the Tapsilat API'
  spec.homepage      = 'https://github.com/tapsilat/tapsilat-ruby'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 2.6.0'

  spec.files         = Dir['lib/**/*', 'README.md', 'LICENSE']
  spec.executables   = []
  spec.bindir        = 'bin'
  spec.require_paths = ['lib']

  spec.add_dependency 'httparty', '~> 0.21.0'
  spec.add_dependency 'csv', '~> 3.0'

  spec.add_development_dependency 'bundler', '>= 1.17'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.12'
  spec.add_development_dependency 'rubocop', '~> 1.21'
  spec.add_development_dependency 'rubocop-rspec', '~> 2.4'
  spec.add_development_dependency 'simplecov', '~> 0.22'
  spec.add_development_dependency 'vcr', '~> 6.1'
  spec.add_development_dependency 'webmock', '~> 3.18'
  spec.add_development_dependency 'yard', '~> 0.9'
  spec.metadata['rubygems_mfa_required'] = 'true'
end
