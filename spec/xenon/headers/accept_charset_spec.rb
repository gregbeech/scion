require 'xenon/headers/accept_charset'

describe Xenon::Headers::AcceptCharset do

  context '::parse' do
    it 'can parse a basic charset range' do
      header = Xenon::Headers::AcceptCharset.parse('unicode-1-1;q=0.8')
      expect(header.charset_ranges.size).to eq(1)
      expect(header.charset_ranges[0].to_s).to eq('unicode-1-1; q=0.8')
    end

    it 'can parse the example from RFC 7231 § 5.3.3 with the right precedence' do
      header = Xenon::Headers::AcceptCharset.parse('iso-8859-5, unicode-1-1;q=0.8')
      expect(header.charset_ranges.size).to eq(2)
      expect(header.charset_ranges[0].to_s).to eq('iso-8859-5')
      expect(header.charset_ranges[1].to_s).to eq('unicode-1-1; q=0.8')
    end
  end

  context '#merge' do
    it 'can merge two headers with the right precedence' do
      h1 = Xenon::Headers::AcceptCharset.parse('unicode-1-1;q=0.8')
      h2 = Xenon::Headers::AcceptCharset.parse('iso-8859-5')
      header = h1.merge(h2)
      expect(header.charset_ranges.size).to eq(2)
      expect(header.charset_ranges[0].to_s).to eq('iso-8859-5')
      expect(header.charset_ranges[1].to_s).to eq('unicode-1-1; q=0.8')
    end
  end

end