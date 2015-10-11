require 'xenon/headers/if_range'

describe Xenon::Headers::IfRange do

  context '::parse' do
    it 'can parse an http date' do
      header = Xenon::Headers::IfRange.parse('Sat, 29 Oct 1994 19:43:31 GMT')
      expect(header.date).to eq(Time.utc(1994, 10, 29, 19, 43, 31))
    end

    it 'can parse an obsolete RFC 850 date' do
      header = Xenon::Headers::IfRange.parse('Sunday, 06-Nov-94 08:49:37 GMT')
      expect(header.date).to eq(Time.utc(1994, 11, 6, 8, 49, 37))
    end

    it 'can parse an obsolete asctime date' do
      header = Xenon::Headers::IfRange.parse('Sun Nov  6 08:49:37 1994')
      expect(header.date).to eq(Time.utc(1994, 11, 6, 8, 49, 37))
    end

    it 'can parse a strong etag' do
      header = Xenon::Headers::IfRange.parse('"xyzzy"')
      expect(header.etag).to_not be_nil
      expect(header.etag.opaque_tag).to eq 'xyzzy'
      expect(header.etag).to be_strong
    end

    it 'should raise a ProtocolError if the etag is weak' do
      expect { Xenon::Headers::IfRange.parse('W/"xyzzy"') }.to raise_error Xenon::ProtocolError
    end
  end

  context '#to_s' do
    it 'returns the http date format for dates' do
      header = Xenon::Headers::IfRange.new(Time.utc(1994, 10, 29, 19, 43, 31))
      expect(header.to_s).to eq('Sat, 29 Oct 1994 19:43:31 GMT')
    end

    it 'returns the etag format for etags' do
      header = Xenon::Headers::IfRange.new(Xenon::ETag.new('xyzzy'))
      expect(header.to_s).to eq('"xyzzy"')
    end
  end

end