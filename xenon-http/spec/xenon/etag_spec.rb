require 'xenon/etag'

describe Xenon::ETag do

  describe '::parse' do
    it 'can parse a strong etag' do
      etag = Xenon::ETag.parse('"xyzzy"')
      expect(etag.tag).to eq 'xyzzy'
      expect(etag).to be_strong
    end

    it 'can parse a weak etag' do
      etag = Xenon::ETag.parse('W/"xyzzy"')
      expect(etag.tag).to eq 'xyzzy'
      expect(etag).to be_weak
    end
  end

end
