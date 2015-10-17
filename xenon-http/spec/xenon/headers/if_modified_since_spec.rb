require 'xenon/headers/if_modified_since'

describe Xenon::Headers::IfModifiedSince do

  context '::parse' do
    it 'can parse an http date' do
      header = Xenon::Headers::IfModifiedSince.parse('Sat, 29 Oct 1994 19:43:31 GMT')
      expect(header.date).to eq(Time.utc(1994, 10, 29, 19, 43, 31))
    end
  end

  context '#to_s' do
    it 'returns the http date format' do
      header = Xenon::Headers::IfModifiedSince.new(Time.utc(1994, 10, 29, 19, 43, 31))
      expect(header.to_s).to eq('Sat, 29 Oct 1994 19:43:31 GMT')
    end
  end

end