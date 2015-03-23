require 'xenon/headers/if_match'

describe Xenon::Headers::IfMatch do

  context '::parse' do
    it 'can parse a single etag' do
      header = Xenon::Headers::IfMatch.parse('"xyzzy"')
      expect(header.etags.size).to eq(1)
      expect(header.etags[0]).to eq(Xenon::ETag.new('xyzzy'))
    end

    it 'can parse multiple etags' do
      header = Xenon::Headers::IfMatch.parse('"xyzzy", "r2d2xxxx", "c3piozzzz"')
      expect(header.etags.size).to eq(3)
      expect(header.etags[0]).to eq(Xenon::ETag.new('xyzzy'))
      expect(header.etags[1]).to eq(Xenon::ETag.new('r2d2xxxx'))
      expect(header.etags[2]).to eq(Xenon::ETag.new('c3piozzzz'))
    end

    it 'can parse a wildcard header' do
      header = Xenon::Headers::IfMatch.parse('*')
      expect(header.etags.size).to eq(0)
    end
  end

  context '#merge' do
    it 'can merge two headers and maintain etag order' do
      h1 = Xenon::Headers::IfMatch.parse('"xyzzy", "r2d2xxxx"')
      h2 = Xenon::Headers::IfMatch.parse('"c3piozzzz"')
      header = h1.merge(h2)
      expect(header.etags.size).to eq(3)
      expect(header.etags[0]).to eq(Xenon::ETag.new('xyzzy'))
      expect(header.etags[1]).to eq(Xenon::ETag.new('r2d2xxxx'))
      expect(header.etags[2]).to eq(Xenon::ETag.new('c3piozzzz'))
    end

    it 'raises a protocol error when trying to merge into a wildcard header' do
      h1 = Xenon::Headers::IfMatch.parse('*')
      h2 = Xenon::Headers::IfMatch.parse('"c3piozzzz"')
      expect { h1.merge(h2) }.to raise_error(Xenon::ProtocolError)
    end

    it 'raises a protocol error when trying to merge a wildcard into a header' do
      h1 = Xenon::Headers::IfMatch.parse('"xyzzy"')
      h2 = Xenon::Headers::IfMatch.parse('*')
      expect { h1.merge(h2) }.to raise_error(Xenon::ProtocolError)
    end

    it 'raises a protocol error when trying to merge two wildcard headers' do
      h1 = Xenon::Headers::IfMatch.parse('*')
      h2 = Xenon::Headers::IfMatch.parse('*')
      expect { h1.merge(h2) }.to raise_error(Xenon::ProtocolError)
    end
  end

  context '#to_s' do
    it 'returns the string representation a single etag' do
      header = Xenon::Headers::IfMatch.parse('"xyzzy"')
      expect(header.to_s).to eq('"xyzzy"')
    end

    it 'returns the string representation of multiple etags' do
      header = Xenon::Headers::IfMatch.parse('"xyzzy", "r2d2xxxx", "c3piozzzz"')
      expect(header.to_s).to eq('"xyzzy", "r2d2xxxx", "c3piozzzz"')
    end

    it 'returns the string representation of a wildcard header' do
      header = Xenon::Headers::IfMatch.wildcard
      expect(header.to_s).to eq('*')
    end
  end

end