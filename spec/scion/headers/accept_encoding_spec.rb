require 'scion/headers/accept_encoding'

describe Scion::Headers::AcceptEncoding do

  context '::parse' do
    %w(identity compress x-compress deflate gzip x-gzip *).each do |cc|
      it "can parse the #{cc} content coding" do
        header = Scion::Headers::AcceptEncoding.parse(cc)
        expect(header.coding_ranges.size).to eq(1)
        expect(header.coding_ranges[0].to_s).to eq(cc)
      end
    end

    it 'can parse the fifth example from RFC 7231 § 5.3.4 with the right precedence' do
      header = Scion::Headers::AcceptEncoding.parse('gzip;q=1.0, identity; q=0.5, *;q=0')
      expect(header.coding_ranges.size).to eq(3)
      expect(header.coding_ranges[0].to_s).to eq('gzip')
      expect(header.coding_ranges[1].to_s).to eq('identity; q=0.5')
      expect(header.coding_ranges[2].to_s).to eq('*; q=0.0')
    end

    it 'parses an empty header as containing no codings' do
      header = Scion::Headers::AcceptEncoding.parse('')
      expect(header.coding_ranges.size).to eq(0) 
    end
  end

end