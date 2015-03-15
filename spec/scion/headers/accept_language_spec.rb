require 'scion/headers/accept_language'

describe Scion::Headers::AcceptLanguage do

  context '::parse' do
    it 'can parse a basic language range' do
      header = Scion::Headers::AcceptLanguage.parse('en-gb;q=0.8')
      expect(header.language_ranges.size).to eq(1)
      expect(header.language_ranges[0].to_s).to eq('en-gb; q=0.8')
    end

    it 'can parse the example from RFC 7231 § 5.3.5 with the right precedence' do
      header = Scion::Headers::AcceptLanguage.parse('da, en-gb;q=0.8, en;q=0.7')
      expect(header.language_ranges.size).to eq(3)
      expect(header.language_ranges[0].to_s).to eq('da')
      expect(header.language_ranges[1].to_s).to eq('en-gb; q=0.8')
      expect(header.language_ranges[2].to_s).to eq('en; q=0.7')
    end
  end

  context '#merge' do
    it 'can merge two headers with the right precedence' do
      h1 = Scion::Headers::AcceptLanguage.parse('da, en;q=0.7')
      h2 = Scion::Headers::AcceptLanguage.parse('en-gb;q=0.8')
      header = h1.merge(h2)
      expect(header.language_ranges.size).to eq(3)
      expect(header.language_ranges[0].to_s).to eq('da')
      expect(header.language_ranges[1].to_s).to eq('en-gb; q=0.8')
      expect(header.language_ranges[2].to_s).to eq('en; q=0.7')
    end
  end

end