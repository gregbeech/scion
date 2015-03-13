require 'scion/headers/accept_charset'

describe Scion::Headers::AcceptCharset do

  context '::parse' do
    it 'can parse the example from RFC 7231 § 5.3.3 with the right precedence' do
      header = Scion::Headers::AcceptCharset.parse('iso-8859-5, unicode-1-1;q=0.8')
      expect(header.charset_ranges.size).to eq(2)
      expect(header.charset_ranges[0].to_s).to eq('iso-8859-5')
      expect(header.charset_ranges[1].to_s).to eq('unicode-1-1; q=0.8')
    end
  end

end