# frozen_string_literal: true

RSpec.describe Faraday::Gzip::Middleware do
  require 'brotli' if described_class::BROTLI_SUPPORTED

  subject(:middleware) do
    described_class.new(->(env) { Faraday::Response.new(env) })
  end

  let(:uncompressed_body) do
    '<html><head><title>Rspec</title></head><body>Hello, spec!</body></html>'
  end

  describe 'request headers' do
    it 'sets Accept-Encoding when missing' do
      res = process_through_middleware(middleware, body: '', headers: {})
      encodings = described_class::BROTLI_SUPPORTED ? 'gzip,deflate,br' : 'gzip,deflate'
      expect(res.env[:request_headers][:accept_encoding]).to eq(encodings)
    end

    it 'does not overwrite existing Accept-Encoding' do
      res = process_through_middleware(middleware, body: '', headers: {}) do |env|
        env[:request_headers][:accept_encoding] = 'zopfli'
      end

      expect(res.env[:request_headers][:accept_encoding]).to eq('zopfli')
    end
  end

  describe 'response decoding' do
    shared_examples 'decoded response' do
      it 'decodes body' do
        expect(response.body).to eq(uncompressed_body)
      end

      it 'sets Content-Length to decoded bytesize' do
        expect(response.headers['Content-Length']).to eq(uncompressed_body.bytesize)
      end

      it 'removes Content-Encoding' do
        expect(response.headers['Content-Encoding']).to be_nil
      end
    end

    context 'when gzip' do
      let(:compressed) { gzip_deflate(uncompressed_body) }
      let(:response) do
        process_through_middleware(
          middleware,
          body: compressed,
          headers: { 'Content-Encoding' => 'gzip', 'Content-Length' => compressed.bytesize }
        )
      end

      it_behaves_like 'decoded response'
    end

    context 'when deflate (zlib wrapper)' do
      let(:compressed) { zlib_deflate(uncompressed_body) }
      let(:response) do
        process_through_middleware(
          middleware,
          body: compressed,
          headers: { 'Content-Encoding' => 'deflate', 'Content-Length' => compressed.bytesize }
        )
      end

      it_behaves_like 'decoded response'
    end

    context 'when deflate (raw stream)' do
      let(:compressed) { raw_deflate(uncompressed_body) }
      let(:response) do
        process_through_middleware(
          middleware,
          body: compressed,
          headers: { 'Content-Encoding' => 'deflate', 'Content-Length' => compressed.bytesize }
        )
      end

      it_behaves_like 'decoded response'
    end

    context 'when brotli', if: described_class::BROTLI_SUPPORTED do
      let(:compressed) { Brotli.deflate(uncompressed_body) }
      let(:response) do
        process_through_middleware(
          middleware,
          body: compressed,
          headers: { 'Content-Encoding' => 'br', 'Content-Length' => compressed.bytesize }
        )
      end

      it_behaves_like 'decoded response'
    end

    context 'when multiple encodings', if: described_class::BROTLI_SUPPORTED do
      let(:compressed) { Brotli.deflate(gzip_deflate(uncompressed_body)) }
      let(:response) do
        process_through_middleware(
          middleware,
          body: compressed,
          headers: { 'Content-Encoding' => 'gzip, br', 'Content-Length' => compressed.bytesize }
        )
      end

      it_behaves_like 'decoded response'
    end

    context 'with Content-Encoding normalization (spaces/case)' do
      let(:compressed) { gzip_deflate(uncompressed_body) }
      let(:response) do
        process_through_middleware(
          middleware,
          body: compressed,
          headers: { 'Content-Encoding' => ' GZip ', 'Content-Length' => compressed.bytesize }
        )
      end

      it_behaves_like 'decoded response'
    end

    context 'when Content-Length provided as string' do
      let(:compressed) { gzip_deflate(uncompressed_body) }
      let(:response) do
        process_through_middleware(
          middleware,
          body: compressed,
          headers: { 'Content-Encoding' => 'gzip', 'Content-Length' => compressed.bytesize.to_s }
        )
      end

      it_behaves_like 'decoded response'
    end
  end

  describe 'edge cases' do
    it 'removes Content-Encoding for empty body and preserves length' do
      res = process_through_middleware(
        middleware,
        body: '',
        headers: { 'Content-Encoding' => 'gzip', 'Content-Length' => 0 }
      )

      expect(res.headers['Content-Length']).to eq(0)
      expect(res.headers['Content-Encoding']).to be_nil
    end

    it 'removes Content-Encoding for nil body and preserves length' do
      res = process_through_middleware(
        middleware,
        body: nil,
        headers: { 'Content-Encoding' => 'gzip', 'Content-Length' => 0 }
      )

      expect(res.headers['Content-Length']).to eq(0)
      expect(res.headers['Content-Encoding']).to be_nil
    end

    it 'does not modify identity responses' do
      res = process_through_middleware(
        middleware,
        body: uncompressed_body,
        headers: { 'Content-Encoding' => 'identity', 'Content-Length' => uncompressed_body.bytesize }
      )

      expect(res.body).to eq(uncompressed_body)
      expect(res.headers['Content-Encoding']).to eq('identity')
    end

    it 'does not modify unsupported encodings' do
      res = process_through_middleware(
        middleware,
        body: 'unsupported',
        headers: { 'Content-Encoding' => 'unsupported' }
      )

      expect(res.body).to eq('unsupported')
      expect(res.headers['Content-Encoding']).to eq('unsupported')
    end

    it 'does nothing when Content-Encoding is missing' do
      res = process_through_middleware(middleware, body: uncompressed_body, headers: {})

      expect(res.body).to eq(uncompressed_body)
      expect(res.headers['Content-Encoding']).to be_nil
    end

    it 'does not touch non-string bodies (stream-like)' do
      stream = StringIO.new(gzip_deflate(uncompressed_body))

      res = process_through_middleware(
        middleware,
        body: stream,
        headers: { 'Content-Encoding' => 'gzip', 'Content-Length' => 123 }
      )

      expect(res.body).to eq(stream)
      expect(res.headers['Content-Encoding']).to eq('gzip')
    end

    it 'treats weird bodies without empty?/size as non-empty and does not touch them' do
      weird = Object.new

      res = process_through_middleware(
        middleware,
        body: weird,
        headers: { 'Content-Encoding' => 'gzip', 'Content-Length' => 123 }
      )

      expect(res.body).to eq(weird)
      expect(res.headers['Content-Encoding']).to eq('gzip')
    end
  end

  describe '.optional_dependency' do
    it 'returns false when require raises LoadError' do
      allow(described_class).to receive(:require).with('nope_nope_nope').and_raise(LoadError)
      expect(described_class.optional_dependency('nope_nope_nope')).to be(false)
    end

    it 'returns false when block raises NameError' do
      expect(described_class.optional_dependency { raise NameError }).to be(false)
    end

    it 'returns true when require succeeds' do
      allow(described_class).to receive(:require).with('some_lib').and_return(true)
      expect(described_class.optional_dependency('some_lib')).to be(true)
    end

    it 'returns true when block succeeds' do
      expect(described_class.optional_dependency { 123 }).to be(true)
    end
  end
end
