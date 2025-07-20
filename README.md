# Faraday Gzip

![CI](https://github.com/bodrovis/faraday-gzip/actions/workflows/ci.yaml/badge.svg)
[![Gem](https://img.shields.io/gem/v/faraday-gzip.svg?style=flat-square)](https://rubygems.org/gems/faraday-gzip)
![Gem Total Downloads](https://img.shields.io/gem/dt/faraday-gzip)
[![Maintainability](https://qlty.sh/badges/e6c44939-e581-4e4a-9ce0-6bdcbeb41dce/maintainability.svg)](https://qlty.sh/gh/bodrovis/projects/faraday-gzip)
[![Code Coverage](https://qlty.sh/badges/e6c44939-e581-4e4a-9ce0-6bdcbeb41dce/test_coverage.svg)](https://qlty.sh/gh/bodrovis/projects/faraday-gzip)

The `Gzip` middleware for Faraday 1 and 2 adds the necessary `Accept-Encoding` headers and automatically decompresses the response. If the "Accept-Encoding" header isn't set in the request, it defaults to `gzip,deflate` and appropriately handles the server's compressed response. This functionality resembles what Ruby does internally in `Net::HTTP#get`. If [Brotli](https://github.com/miyucy/brotli) is included in your Gemfile, the middleware also adds `br` to the header for Brotli support.

## Prerequisites

* faraday-gzip v3 supports only Faraday v2 and is tested with Ruby 3.0+ and JRuby 9.4+
* [faraday-gzip v2](https://github.com/bodrovis/faraday-gzip/tree/v2) supports Faraday v1 and v2 and is tested with Ruby 2.7+ and JRuby 9.4.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'faraday-gzip', '~> 3'
```

And then execute:

```
bundle install
```

Or install it yourself as:

```
gem install faraday-gzip
```

## Usage

To enable the middleware in your Faraday connection, add it as shown below:

```ruby
require 'faraday/gzip' # <=== Add this line

conn = Faraday.new(...) do |f|
  f.request :gzip # <=== Add this line
  # Additional configuration...
end
```

## Development

To contribute or make changes:

* Clone the repo
* Run `bundle` to install dependencies
* Implement your feature
* Write and run tests using `rspec .`
* Use rake build to build the gem locally if needed
* Create a new PR with your changes

## Contributing

Bug reports and pull requests are welcome on GitHub.

## License

This gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).