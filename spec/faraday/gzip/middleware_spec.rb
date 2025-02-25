# frozen_string_literal: true

RSpec.describe Faraday::Gzip::Middleware do
  require 'brotli' if Faraday::Gzip::Middleware::BROTLI_SUPPORTED

  subject(:middleware) do
    described_class.new(->(env) { Faraday::Response.new(env) })
  end

  let(:headers) { {} }

  def process(body, content_type = nil, options = {})
    env = {
      body: body, request: options,
      request_headers: Faraday::Utils::Headers.new,
      response_headers: Faraday::Utils::Headers.new(headers)
    }
    env[:response_headers]['content-type'] = content_type if content_type
    yield(env) if block_given?
    middleware.call(env)
  end

  context 'when request' do
    it 'sets the Accept-Encoding request header' do
      env = process('').env
      encodings = Faraday::Gzip::Middleware::BROTLI_SUPPORTED ? 'gzip,deflate,br' : 'gzip,deflate'
      expect(env[:request_headers][:accept_encoding]).to eq(encodings)
    end

    it 'doesnt overwrite existing Accept-Encoding request header' do
      env = process('') do |e|
        e[:request_headers][:accept_encoding] = 'zopfli'
      end.env
      expect(env[:request_headers][:accept_encoding]).to eq('zopfli')
    end
  end

  context 'when response' do
    let(:uncompressed_body) do
      '<html><head><title>Rspec</title></head><body>Hello, spec!</body></html>'
    end
    let(:empty_body) { '' }
    let(:gzipped_body) do
      io = StringIO.new
      gz = Zlib::GzipWriter.new(io)
      gz.write(uncompressed_body)
      gz.close
      res = io.string
      res.force_encoding('BINARY')
      res
    end
    let(:deflated_body) do
      Zlib::Deflate.deflate(uncompressed_body)
    end
    let(:raw_deflated_body) do
      z = Zlib::Deflate.new(Zlib::DEFAULT_COMPRESSION, -Zlib::MAX_WBITS)
      compressed_body = z.deflate(uncompressed_body, Zlib::FINISH)
      z.close
      compressed_body
    end

    if Faraday::Gzip::Middleware::BROTLI_SUPPORTED
      let(:brotlied_body) do
        Brotli.deflate(uncompressed_body)
      end
    end

    shared_examples 'compressed response' do
      it 'uncompresses the body' do
        expect(process(body).body).to eq(uncompressed_body)
      end

      it 'sets the correct Content-Length' do
        expect(process(body).headers['Content-Length']).to eq(uncompressed_body.bytesize)
      end

      it 'removes the Content-Encoding' do
        expect(process(body).headers['Content-Encoding']).to be_nil
      end
    end

    context 'when gzipped response' do
      let(:body) { gzipped_body }
      let(:headers) { { 'Content-Encoding' => 'gzip', 'Content-Length' => body.length } }

      it_behaves_like 'compressed response'
    end

    context 'when deflated response' do
      let(:body) { deflated_body }
      let(:headers) { { 'Content-Encoding' => 'deflate', 'Content-Length' => body.length } }

      it_behaves_like 'compressed response'
    end

    context 'when raw deflated response' do
      let(:body) { raw_deflated_body }
      let(:headers) { { 'Content-Encoding' => 'deflate', 'Content-Length' => body.length } }

      it_behaves_like 'compressed response'
    end

    if Faraday::Gzip::Middleware::BROTLI_SUPPORTED
      context 'when brotlied response' do
        let(:body) { brotlied_body }
        let(:headers) { { 'Content-Encoding' => 'br', 'Content-Length' => body.length } }

        it_behaves_like 'compressed response'
      end
    end

    context 'when empty response' do
      let(:body) { empty_body }
      let(:headers) { { 'Content-Encoding' => 'gzip', 'Content-Length' => body.length } }

      it 'sets the Content-Length' do
        expect(process(body).headers['Content-Length']).to eq(empty_body.length)
      end

      it 'removes the Content-Encoding' do
        expect(process(body).headers['Content-Encoding']).to be_nil
      end
    end

    context 'when nil response' do
      let(:body) { nil }
      let(:headers) { { 'Content-Encoding' => 'gzip', 'Content-Length' => 0 } }

      it 'sets the Content-Length' do
        expect(process(body).headers['Content-Length']).to eq(0)
      end

      it 'removes the Content-Encoding' do
        expect(process(body).headers['Content-Encoding']).to be_nil
      end
    end

    context 'when identity response' do
      let(:body) { uncompressed_body }

      it 'does not modify the body' do
        expect(process(body).body).to eq(uncompressed_body)
      end
    end

    context 'when unsupported encoding response' do
      let(:body) { 'unsupported' }
      let(:headers) { { 'Content-Encoding' => 'unsupported' } }

      it 'does not modify the body' do
        expect(process(body).body).to eq(body)
      end

      it 'preserves the Content-Encoding header' do
        expect(process(body).headers['Content-Encoding']).to eq('unsupported')
      end
    end

    context 'when no Content-Encoding header' do
      let(:body) { uncompressed_body }
      let(:headers) { {} }

      it 'does not modify the body' do
        expect(process(body).body).to eq(uncompressed_body)
      end

      it 'does not add a Content-Encoding header' do
        expect(process(body).headers['Content-Encoding']).to be_nil
      end
    end

    context 'when Content-Length is a string' do
      let(:body) { gzipped_body }
      let(:headers) { { 'Content-Encoding' => 'gzip', 'Content-Length' => body.length.to_s } }

      it_behaves_like 'compressed response'
    end
  end
end
