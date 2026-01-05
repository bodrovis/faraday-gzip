# frozen_string_literal: true

require 'zlib'
require 'stringio'

module FaradayGzipSpecHelpers
  def process_through_middleware(middleware, body:, headers: {}, content_type: nil, request_options: {})
    env = {
      body: body,
      request: request_options,
      request_headers: Faraday::Utils::Headers.new,
      response_headers: Faraday::Utils::Headers.new(headers)
    }

    env[:response_headers]['content-type'] = content_type if content_type
    yield(env) if block_given?

    middleware.call(env)
  end

  def gzip_deflate(str)
    io = StringIO.new
    gz = Zlib::GzipWriter.new(io)
    gz.write(str)
    gz.close
    io.string.force_encoding('BINARY')
  end

  def zlib_deflate(str)
    Zlib::Deflate.deflate(str)
  end

  def raw_deflate(str)
    z = Zlib::Deflate.new(Zlib::DEFAULT_COMPRESSION, -Zlib::MAX_WBITS)
    compressed = z.deflate(str, Zlib::FINISH)
    z.close
    compressed
  end
end
