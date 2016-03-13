require 'xenon/headers/cookie'

describe Xenon::Headers::Cookie do

  context '::parse' do
    it 'can parse a single cookie' do
      header = described_class.parse('foo=bar')
      expect(header.cookies.size).to eq(1)
      expect(header.cookies).to eq('foo' => 'bar')
    end

    it 'can parse multiple cookies' do
      header = described_class.parse('foo=bar; baz=quux; x=y')
      expect(header.cookies.size).to eq(3)
      expect(header.cookies).to eq('foo' => 'bar', 'baz' => 'quux', 'x' => 'y')
    end

    it 'does not allow whitespace around the equals sign' do
      expect { described_class.parse('foo =bar') }.to raise_error Xenon::ParseError
      expect { described_class.parse('foo= bar') }.to raise_error Xenon::ParseError
    end
  end

end