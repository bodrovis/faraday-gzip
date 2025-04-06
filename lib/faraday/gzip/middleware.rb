# frozen_string_literal: true

require 'zlib'
require 'stringio'

# Middleware to automatically decompress response bodies. If the
# "Accept-Encoding" header wasn't set in the request, this sets it to
# "gzip,deflate" and appropriately handles the compressed response from the
# server. This resembles what Ruby 1.9+ does internally in Net::HTTP#get.
# Based on https://github.com/lostisland/faraday_middleware/blob/main/lib/faraday_middleware/gzip.rb
module Faraday
  # Main module
  module Gzip
    # Faraday middleware for decompression
    class Middleware < Faraday::Middleware
      # System method required by Faraday
      def self.optional_dependency(lib = nil)
        lib ? require(lib) : yield
        true
      rescue LoadError, NameError
        false
      end

      BROTLI_SUPPORTED = optional_dependency 'brotli'

      # Returns supported encodings, adds brotli if the corresponding
      # dependency is present
      def self.supported_encodings
        encodings = %w[gzip deflate]
        encodings << 'br' if BROTLI_SUPPORTED
        encodings
      end

      ACCEPT_ENCODING = 'Accept-Encoding'
      CONTENT_ENCODING = 'Content-Encoding'
      CONTENT_LENGTH = 'Content-Length'
      SUPPORTED_ENCODINGS = supported_encodings.join(',').freeze

      # Main method to process the response
      def call(env)
        env[:request_headers][ACCEPT_ENCODING] ||= SUPPORTED_ENCODINGS

        @app.call(env).on_complete do |response_env|
          reset_body(response_env, find_processor(response_env))
        end
      end

      # Finds a proper processor
      def find_processor(response_env)
        if empty_body?(response_env)
          ->(body) { raw_body(body) }
        else
          processors[response_env[:response_headers][CONTENT_ENCODING]]
        end
      end

      # Calls the proper processor to decompress body
      def reset_body(env, processor)
        return if processor.nil?

        env[:body] = processor.call(env[:body])
        env[:response_headers].delete(CONTENT_ENCODING)

        env[:response_headers][CONTENT_LENGTH] = env[:body].nil? ? 0 : env[:body].length
      end

      # Process gzip
      def uncompress_gzip(body)
        io = StringIO.new(body)
        gzip_reader = Zlib::GzipReader.new(io, encoding: 'ASCII-8BIT')
        begin
          gzip_reader.read
        ensure
          gzip_reader.close
        end
      end

      # Process deflate
      def inflate(body)
        # Inflate as a DEFLATE (RFC 1950+RFC 1951) stream
        Zlib::Inflate.inflate(body)
      rescue Zlib::DataError
        # Fall back to inflating as a "raw" deflate stream which
        # Microsoft servers return
        inflate = Zlib::Inflate.new(-Zlib::MAX_WBITS)
        begin
          inflate.inflate(body)
        ensure
          inflate.close
        end
      end

      # Process brotli
      def brotli_inflate(body)
        Brotli.inflate(body)
      end

      # Do not process anything, leave body as is
      def raw_body(body)
        body
      end

      private

      def empty_body?(response_env)
        response_env[:body].nil? || response_env[:body].empty?
      end

      # Method providing the processors
      def processors
        @processors ||= {
          'gzip' => ->(body) { uncompress_gzip(body) },
          'deflate' => ->(body) { inflate(body) },
          'br' => ->(body) { brotli_inflate(body) }
        }
      end
    end
  end
end
