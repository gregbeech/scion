require 'xenon/headers/if_unmodified_since'

describe Xenon::Headers::IfUnmodifiedSince do

  context '::parse' do
    it 'can parse an http date' do
      header = Xenon::Headers::IfUnmodifiedSince.parse('Sat, 29 Oct 1994 19:43:31 GMT')
      expect(header.date).to eq(Time.utc(1994, 10, 29, 19, 43, 31))
    end
  end

  context '#to_s' do
    it 'returns the http date format' do
      header = Xenon::Headers::IfUnmodifiedSince.new(Time.utc(1994, 10, 29, 19, 43, 31))
      expect(header.to_s).to eq('Sat, 29 Oct 1994 19:43:31 GMT')
    end
  end

end