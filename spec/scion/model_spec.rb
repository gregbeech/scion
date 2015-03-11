require 'scion/model'

describe Scion::MediaType do

  context '::parse' do
    it 'can parse basic media types' do
      mt = Scion::MediaType.parse('application/json')
      expect(mt.type).to eq('application')
      expect(mt.subtype).to eq('json')
    end

    it 'can parse media types with parameters' do
      mt = Scion::MediaType.parse('text/plain; format=flowed; paged')
      expect(mt.type).to eq('text')
      expect(mt.subtype).to eq('plain')
      expect(mt.params).to eq({ 'format' => 'flowed', 'paged' => nil })
    end

    it 'strips whitespace around separators' do
      mt = Scion::MediaType.parse('text/plain ; format = flowed ; paged')
      expect(mt.type).to eq('text')
      expect(mt.subtype).to eq('plain')
      expect(mt.params).to eq({ 'format' => 'flowed', 'paged' => nil })
    end

    it 'raises an error when the media type contains wildcards' do
      expect { Scion::MediaType.parse('*/*') }.to raise_error(Scion::ParseError)
      expect { Scion::MediaType.parse('application/*') }.to raise_error(Scion::ParseError)
    end

    it 'raises an error when the media type is invalid' do
      expect { Scion::MediaType.parse('application') }.to raise_error(Scion::ParseError)
      expect { Scion::MediaType.parse('application; foo=bar') }.to raise_error(Scion::ParseError)
      expect { Scion::MediaType.parse('/json') }.to raise_error(Scion::ParseError)
      expect { Scion::MediaType.parse('/json; foo=bar') }.to raise_error(Scion::ParseError)
    end
  end

  context '#to_s' do
    it 'returns the string representation of a media type' do
      mt = Scion::MediaType.new('text', 'plain', 'format' => 'flowed', 'paged' => nil)
      expect(mt.to_s).to eq('text/plain; format=flowed; paged')
    end
  end
  
end

describe Scion::MediaRange do



  context '::parse' do
    it 'can parse basic media ranges' do
      mt = Scion::MediaRange.parse('application/json')
      expect(mt.type).to eq('application')
      expect(mt.subtype).to eq('json')
    end

    it 'can parse media ranges with parameters' do
      mt = Scion::MediaRange.parse('text/plain; format=flowed; paged')
      expect(mt.type).to eq('text')
      expect(mt.subtype).to eq('plain')
      expect(mt.params).to eq({ 'format' => 'flowed', 'paged' => nil })
    end

    it 'strips whitespace around separators' do
      mt = Scion::MediaRange.parse('text/plain ; format = flowed ; paged')
      expect(mt.type).to eq('text')
      expect(mt.subtype).to eq('plain')
      expect(mt.params).to eq({ 'format' => 'flowed', 'paged' => nil })
    end

    it 'can parse media ranges with subtype wildcards' do
      mt = Scion::MediaRange.parse('application/*')
      expect(mt.type).to eq('application')
      expect(mt.subtype).to eq('*')
    end

    it 'can parse media ranges with type and subtype wildcards' do
      mt = Scion::MediaRange.parse('*/*')
      expect(mt.type).to eq('*')
      expect(mt.subtype).to eq('*')
    end

    it 'can parse basic media ranges' do
      mt = Scion::MediaRange.parse('application/json')
      expect(mt.type).to eq('application')
      expect(mt.subtype).to eq('json')
    end

    it 'raises an error when the media range is invalid' do
      expect { Scion::MediaRange.parse('application') }.to raise_error(Scion::ParseError)
      expect { Scion::MediaRange.parse('application; foo=bar') }.to raise_error(Scion::ParseError)
      expect { Scion::MediaRange.parse('*/json') }.to raise_error(Scion::ParseError)
      expect { Scion::MediaRange.parse('/json') }.to raise_error(Scion::ParseError)
      expect { Scion::MediaRange.parse('/json; foo=bar') }.to raise_error(Scion::ParseError)
    end
  end

  context '#=~' do
    it 'returns true when the type and subtype are wildcards' do
      mr = Scion::MediaRange.new('*', '*')
      mt = Scion::MediaType.new('application', 'json')
      expect(mr =~ mt).to eq(true)
    end

    it 'returns true when the type matches and subtype is a wildcard' do
      mr = Scion::MediaRange.new('application', '*')
      mt = Scion::MediaType.new('application', 'json')
      expect(mr =~ mt).to eq(true)
    end

    it 'returns true when the type and subtype match exactly' do
      mr = Scion::MediaRange.new('application', 'json')
      mt = Scion::MediaType.new('application', 'json')
      expect(mr =~ mt).to eq(true)
    end

    it 'returns true when the type, subtype and parameters match exactly' do
      mr = Scion::MediaRange.new('text', 'plain', 'format' => 'flowed')
      mt = Scion::MediaType.new('text', 'plain', 'format' => 'flowed', 'paged' => nil)
      expect(mr =~ mt).to eq(true)
    end

    it 'returns true when the the media type has more specific parameters' do
      mr = Scion::MediaRange.new('text', 'plain')
      mt = Scion::MediaType.new('text', 'plain', 'format' => 'flowed', 'paged' => nil)
      expect(mr =~ mt).to eq(true)
    end

    it 'returns false when the type is different' do
      mr = Scion::MediaRange.new('text', 'json')
      mt = Scion::MediaType.new('application', 'json')
      expect(mr =~ mt).to eq(false)
    end

    it 'returns false when the type matches but subtype is different' do
      mr = Scion::MediaRange.new('application', 'xml')
      mt = Scion::MediaType.new('application', 'json')
      expect(mr =~ mt).to eq(false)
    end

    it 'returns false when the media range has more specific parameters' do
      mr = Scion::MediaRange.new('text', 'plain', 'format' => 'flowed', 'paged' => nil)
      mt = Scion::MediaType.new('text', 'plain')
      expect(mr =~ mt).to eq(false)
    end

    it 'returns false when the media range has a different parameter value' do
      mr = Scion::MediaRange.new('text', 'plain', 'format' => 'flowed')
      mt = Scion::MediaType.new('text', 'plain', 'format' => 'linear')
      expect(mr =~ mt).to eq(false)
    end
  end

  context '#===' do
    it 'matches compatible media types in a case expression' do
      matches = case Scion::MediaType.new('application', 'json')
                when Scion::MediaRange.new('application', 'json') then true
                else false
                end
      expect(matches).to eq(true)
    end

    it 'does not match incompatible media types in a case expression' do
      matches = case Scion::MediaType.new('application', 'json')
                when Scion::MediaRange.new('application', 'xml') then true
                else false
                end
      expect(matches).to eq(false)
    end
  end

end