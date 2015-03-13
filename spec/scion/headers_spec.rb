require 'scion/headers'

describe Scion::Headers::Accept do

  context '::parse' do
    it 'can parse the first example from RFC 7231 § 5.3.2 with the right precedence' do
      header = Scion::Headers::Accept.parse('text/plain; q=0.5, text/html, text/x-dvi; q=0.8, text/x-c')
      expect(header.media_ranges.size).to eq(4)
      expect(header.media_ranges[0].to_s).to eq('text/html')
      expect(header.media_ranges[1].to_s).to eq('text/x-c')
      expect(header.media_ranges[2].to_s).to eq('text/x-dvi; q=0.8')
      expect(header.media_ranges[3].to_s).to eq('text/plain; q=0.5')
    end

    it 'can parse the second example from RFC 7231 § 5.3.2 with the right precedence' do
      header = Scion::Headers::Accept.parse('text/*, text/plain, text/plain;format=flowed, */*')
      expect(header.media_ranges.size).to eq(4)
      expect(header.media_ranges[0].to_s).to eq('text/plain; format=flowed')
      expect(header.media_ranges[1].to_s).to eq('text/plain')
      expect(header.media_ranges[2].to_s).to eq('text/*')
      expect(header.media_ranges[3].to_s).to eq('*/*')
    end

    it 'can parse the third example from RFC 7231 § 5.3.2 with the right precedence' do
      header = Scion::Headers::Accept.parse('text/*;q=0.3, text/html;q=0.7, text/html;level=1, text/html;level=2;q=0.4, */*;q=0.5')
      expect(header.media_ranges.size).to eq(5)
      expect(header.media_ranges[0].to_s).to eq('text/html; level=1')
      expect(header.media_ranges[1].to_s).to eq('text/html; level=2; q=0.4')
      expect(header.media_ranges[2].to_s).to eq('text/html; q=0.7')
      expect(header.media_ranges[3].to_s).to eq('text/*; q=0.3')
      expect(header.media_ranges[4].to_s).to eq('*/*; q=0.5')
    end
  end

end

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