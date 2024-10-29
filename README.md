# Faraday Gzip

![CI](https://github.com/bodrovis/faraday-gzip/actions/workflows/ci.yaml/badge.svg)
[![Gem](https://img.shields.io/gem/v/faraday-gzip.svg?style=flat-square)](https://rubygems.org/gems/faraday-gzip)
![Gem Total Downloads](https://img.shields.io/gem/dt/faraday-gzip)

The `Gzip` middleware for Faraday 1 and 2 adds the necessary `Accept-Encoding` headers and automatically decompresses the response. If the "Accept-Encoding" header wasn't set in the request, this sets it to "gzip,deflate" and appropriately handles the compressed response from the server. This resembles what Ruby does internally in Net::HTTP#get. If [Brotli](https://github.com/miyucy/brotli) is added to the Gemfile, it will also add "br" to the header.

## Prerequisites

This gem is tested with Ruby 2.7+ and JRuby 9.4+. Faraday 1 and 2 is supported.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'faraday-gzip'
```

And then execute:

```shell
bundle install
```

Or install it yourself as:

```shell
gem install faraday-gzip
```

## Usage

```ruby
require 'faraday/gzip' # <=== add this line

conn = Faraday.new(...) do |f|
  f.request :gzip # <=== add this line
  #...
end
```

## Development

* Check out repo
* `bundle`
* Implement your feature
* Write tests, use `rspec .` to run the tests
* `rake build` to build locally
* Create a new PR

## Contributing

Bug reports and pull requests are welcome on GitHub.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
