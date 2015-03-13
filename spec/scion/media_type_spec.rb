require 'scion/media_type'

describe Scion::MediaType do

  context '::parse' do
    it 'can parse basic media types' do
      mt = Scion::MediaType.parse('application/json')
      expect(mt.type).to eq('application')
      expect(mt.subtype).to eq('json')
    end
    it 'can parse media types with a subtype suffix' do
      mt = Scion::MediaType.parse('application/rss+xml')
      expect(mt.type).to eq('application')
      expect(mt.subtype).to eq('rss+xml')
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

  %w(application audio image message multipart text video).each do |type|
    context "#{type}?" do
      it "returns true when the root type is '#{type}'" do
        mt = Scion::MediaType.new(type, 'dummy')
        expect(mt.send("#{type}?")).to eq(true)
      end

      it "returns false when the root type is not '#{type}'" do
        mt = Scion::MediaType.new('dummy', 'dummy')
        expect(mt.send("#{type}?")).to eq(false)
      end
    end
  end

  { experimental?: 'x', personal?: 'prs', vendor?: 'vnd' }.each do |method, prefix|
    context method do
      it "returns true when the subtype starts with '#{prefix}.'" do
        mt = Scion::MediaType.new('application', "#{prefix}.dummy")
        expect(mt.send(method)).to eq(true)
      end

      it "returns false when the subtype does not start with '#{prefix}.'" do
        mt = Scion::MediaType.new('application', "dummy.dummy")
        expect(mt.send(method)).to eq(false)
      end
    end
  end

  %w(ber der fastinfoset json wbxml xml zip).each do |format|
    context "#{format}?" do
      it "returns true when the subtype is '#{format}'" do
        mt = Scion::MediaType.new('application', format)
        expect(mt.send("#{format}?")).to eq(true)
      end

      it "returns true when the subtype ends with '+#{format}'" do
        mt = Scion::MediaType.new('application', "dummy+#{format}")
        expect(mt.send("#{format}?")).to eq(true)
      end

      it "returns false when the subtype is not '#{format}' and does not end with '+#{format}'" do
        mt = Scion::MediaType.new('dummy', 'dummy+dummy')
        expect(mt.send("#{format}?")).to eq(false)
      end
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

    it 'extracts q from the parameters' do
      mt = Scion::MediaRange.parse('text/plain; q=0.8; format=flowed; paged')
      expect(mt.type).to eq('text')
      expect(mt.subtype).to eq('plain')
      expect(mt.q).to eq(0.8)
      expect(mt.params).to eq({ 'format' => 'flowed', 'paged' => nil })
    end

    it 'uses the default value for q if the value is not numeric' do
      mt = Scion::MediaRange.parse('application/json; q=foo')
      expect(mt.type).to eq('application')
      expect(mt.subtype).to eq('json')
      expect(mt.q).to eq(Scion::MediaRange::DEFAULT_Q)
    end

    it 'raises an error when the media range is invalid' do
      expect { Scion::MediaRange.parse('application') }.to raise_error(Scion::ParseError)
      expect { Scion::MediaRange.parse('application; foo=bar') }.to raise_error(Scion::ParseError)
      expect { Scion::MediaRange.parse('*/json') }.to raise_error(Scion::ParseError)
      expect { Scion::MediaRange.parse('/json') }.to raise_error(Scion::ParseError)
      expect { Scion::MediaRange.parse('/json; foo=bar') }.to raise_error(Scion::ParseError)
    end
  end

  context '#<=>' do
    it 'considers a wildcard type less than a regular type' do
      mr1 = Scion::MediaRange.new('*', '*')
      mr2 = Scion::MediaRange.new('text', '*')
      expect(mr1 <=> mr2).to eq(-1)
    end

    it 'considers a wildcard subtype less than a regular subtype' do
      mr1 = Scion::MediaRange.new('application', '*')
      mr2 = Scion::MediaRange.new('text', 'plain')
      expect(mr1 <=> mr2).to eq(-1)
    end

    it 'considers media ranges with type and subtype equal' do
      mr1 = Scion::MediaRange.new('application', 'json')
      mr2 = Scion::MediaRange.new('text', 'plain')
      expect(mr1 <=> mr2).to eq(0)
    end

    it 'considers a media range with parameters greater than one without' do
      mr1 = Scion::MediaRange.new('text', 'plain', 'format' => 'flowed')
      mr2 = Scion::MediaRange.new('text', 'plain')
      expect(mr1 <=> mr2).to eq(1)
    end

    it 'does not consider the quality when one media range is more specific' do
      mr1 = Scion::MediaRange.new('application', '*', 'q' => '0.3')
      mr2 = Scion::MediaRange.new('*', '*', 'q' => '0.5')
      expect(mr1 <=> mr2).to eq(1)
    end

    it 'considers the quality when media ranges are equally specific' do
      mr1 = Scion::MediaRange.new('application', 'json', 'q' => '0.8')
      mr2 = Scion::MediaRange.new('application', 'xml')
      expect(mr1 <=> mr2).to eq(-1)
    end
  end

  %i(=~ ===).each do |name|
    context "##{name}" do
      it 'returns true when the type and subtype are wildcards' do
        mr = Scion::MediaRange.new('*', '*')
        mt = Scion::MediaType.new('application', 'json')
        expect(mr.send(name, mt)).to eq(true)
      end

      it 'returns true when the type matches and subtype is a wildcard' do
        mr = Scion::MediaRange.new('application', '*')
        mt = Scion::MediaType.new('application', 'json')
        expect(mr.send(name, mt)).to eq(true)
      end

      it 'returns true when the type and subtype match exactly' do
        mr = Scion::MediaRange.new('application', 'json')
        mt = Scion::MediaType.new('application', 'json')
        expect(mr.send(name, mt)).to eq(true)
      end

      it 'returns true when the type, subtype and parameters match exactly' do
        mr = Scion::MediaRange.new('text', 'plain', 'format' => 'flowed')
        mt = Scion::MediaType.new('text', 'plain', 'format' => 'flowed', 'paged' => nil)
        expect(mr.send(name, mt)).to eq(true)
      end

      it 'returns true when the the media type has more specific parameters' do
        mr = Scion::MediaRange.new('text', 'plain')
        mt = Scion::MediaType.new('text', 'plain', 'format' => 'flowed', 'paged' => nil)
        expect(mr.send(name, mt)).to eq(true)
      end

      it 'returns false when the type is different' do
        mr = Scion::MediaRange.new('text', 'json')
        mt = Scion::MediaType.new('application', 'json')
        expect(mr.send(name, mt)).to eq(false)
      end

      it 'returns false when the type matches but subtype is different' do
        mr = Scion::MediaRange.new('application', 'xml')
        mt = Scion::MediaType.new('application', 'json')
        expect(mr.send(name, mt)).to eq(false)
      end

      it 'returns false when the media range has more specific parameters' do
        mr = Scion::MediaRange.new('text', 'plain', 'format' => 'flowed', 'paged' => nil)
        mt = Scion::MediaType.new('text', 'plain')
        expect(mr.send(name, mt)).to eq(false)
      end

      it 'returns false when the media range has a different parameter value' do
        mr = Scion::MediaRange.new('text', 'plain', 'format' => 'flowed')
        mt = Scion::MediaType.new('text', 'plain', 'format' => 'linear')
        expect(mr.send(name, mt)).to eq(false)
      end
    end
  end

  context '#to_s' do
    it 'returns the string representation of a media range' do
      mt = Scion::MediaRange.new('text', 'plain', 'q' => 0.8, 'format' => 'flowed', 'paged' => nil)
      expect(mt.to_s).to eq('text/plain; format=flowed; paged; q=0.8')
    end

    it 'omits the q parameter when it is 1.0' do
      mt = Scion::MediaRange.new('application', 'json', 'q' => 1.0)
      expect(mt.to_s).to eq('application/json')
    end
  end

end
