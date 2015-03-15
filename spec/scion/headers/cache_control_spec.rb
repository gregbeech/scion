require 'scion/headers/cache_control'

describe Scion::Headers::CacheControl do

  context '::parse' do
    ['max-age', 'max-stale', 'min-fresh', 's-maxage'].each do |dir|
      it "can parse the #{dir} directive" do
        header = Scion::Headers::CacheControl.parse("#{dir}=5")
        expect(header.directives.size).to eq(1)
        expect(header.directives[0].to_s).to eq("#{dir}=5")
      end

      it "can parse the #{dir} directive with a quoted value" do # should not be sent by clients but is permitted
        header = Scion::Headers::CacheControl.parse("#{dir}=\"5\"")
        expect(header.directives.size).to eq(1)
        expect(header.directives[0].to_s).to eq("#{dir}=5")
      end
    end

    ['no-cache', 'no-store', 'no-transform', 'only-if-cached', 'must-revalidate', 'public', 'proxy-revalidate'].each do |dir|
      it "can parse the #{dir} directive" do
        header = Scion::Headers::CacheControl.parse("#{dir}")
        expect(header.directives.size).to eq(1)
        expect(header.directives[0].to_s).to eq("#{dir}")
      end
    end

    it "can parse the private directive with no field names" do
      header = Scion::Headers::CacheControl.parse('private')
      expect(header.directives.size).to eq(1)
      expect(header.directives[0].to_s).to eq('private')
    end

    # TODO: private directive with field names

    it 'can parse extension directives with quoted string values' do
      header = Scion::Headers::CacheControl.parse('ext="hello \"world\""')
      expect(header.directives.size).to eq(1)
      expect(header.directives[0].name).to eq('ext')
      expect(header.directives[0].value).to eq("hello \"world\"")
    end

    it 'can parse more complex directives' do
      header = Scion::Headers::CacheControl.parse('public, max-age=3600, must-revalidate')
      expect(header.directives.size).to eq(3)
      expect(header.directives[0].to_s).to eq('public')
      expect(header.directives[1].to_s).to eq('max-age=3600')
      expect(header.directives[2].to_s).to eq('must-revalidate')
    end
  end

  context '#merge' do
    it 'can merge two headers and maintain directive order' do
      h1 = Scion::Headers::CacheControl.parse('public, max-age=3600')
      h2 = Scion::Headers::CacheControl.parse('must-revalidate')
      header = h1.merge(h2)
      expect(header.directives.size).to eq(3)
      expect(header.directives[0].to_s).to eq('public')
      expect(header.directives[1].to_s).to eq('max-age=3600')
      expect(header.directives[2].to_s).to eq('must-revalidate')
    end
  end

end