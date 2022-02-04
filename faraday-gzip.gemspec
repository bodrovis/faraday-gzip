# frozen_string_literal: true

require_relative 'lib/faraday/gzip/version'

Gem::Specification.new do |spec|
  spec.name = 'faraday-gzip'
  spec.version = Faraday::Gzip::VERSION
  spec.authors = ['Ilya Bodrov-Krukowski']
  spec.email = ['golosizpru@gmail.com']

  spec.summary = 'Automatically sets compression headers and decompresses the response'
  spec.description = <<~DESC
    Faraday plugin to automatically set compression headers (GZip, Deflate, Brotli) and decompress the response.
  DESC
  spec.license = 'MIT'

  github_uri = "https://github.com/bodrovis/#{spec.name}"

  spec.homepage = github_uri

  spec.metadata = {
    'bug_tracker_uri' => "#{github_uri}/issues",
    'changelog_uri' => "#{github_uri}/blob/master/CHANGELOG.md",
    'documentation_uri' => "http://www.rubydoc.info/gems/#{spec.name}/#{spec.version}",
    'homepage_uri' => spec.homepage,
    'source_code_uri' => github_uri,
    'rubygems_mfa_required' => 'true'
  }

  spec.files = Dir['lib/**/*', 'README.md', 'LICENSE.md', 'CHANGELOG.md']

  spec.required_ruby_version = '>= 2.6', '< 4'

  spec.add_runtime_dependency 'faraday', '>= 1.0'
  spec.add_runtime_dependency 'zlib', '~> 2.1'

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'simplecov', '~> 0.21.0'

  spec.add_development_dependency 'rubocop', '~> 1.25.0'
  spec.add_development_dependency 'rubocop-packaging', '~> 0.5.0'
  spec.add_development_dependency 'rubocop-performance', '~> 1.0'
  spec.add_development_dependency 'rubocop-rspec', '~> 2.0'
end
