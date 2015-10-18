require 'xenon/etag'

describe Xenon::ETag do
  let(:strong1) { described_class.new('1') }
  let(:weak1) { described_class.new('1', weak: true) }
  let(:weak2) { described_class.new('2', weak: true) }

  describe '::parse' do
    it 'should parse a strong etag' do
      etag = described_class.parse('"xyzzy"')
      expect(etag.tag).to eq 'xyzzy'
      expect(etag).to be_strong
    end
    it 'should parse a weak etag' do
      etag = described_class.parse('W/"xyzzy"')
      expect(etag.tag).to eq 'xyzzy'
      expect(etag).to be_weak
    end
    it 'should raise a ParseError when the string is not a valid etag' do
      expect { described_class.parse('xyzzy') }.to raise_error Xenon::ParseError
      expect { described_class.parse('W/xyzzy') }.to raise_error Xenon::ParseError
      expect { described_class.parse('w/"xyzzy"') }.to raise_error Xenon::ParseError
    end
  end

  describe '#initialize' do
    it 'should freeze the instance' do
      expect(strong1).to be_frozen
    end
  end

  describe '#freeze' do
    it 'should freeze the tag' do
      expect { strong1.tag << 'x' }.to raise_error RuntimeError
    end
  end

  describe '#strong_eq?' do
    it 'should return false for the same weak tags' do
      expect(weak1).to_not be_strong_eq weak1
    end
    it 'should return false for the different weak tags' do
      expect(weak1).to_not be_strong_eq weak2
    end
    it 'should return false for tags that are same but one is weak and one is strong' do
      expect(weak1).to_not be_strong_eq strong1
      expect(strong1).to_not be_strong_eq weak1
    end
    it 'should return true for the same strong tags' do
      expect(strong1).to be_strong_eq strong1
    end
  end

  describe '#weak_eq?' do
    it 'should return true for the same weak tags' do
      expect(weak1).to be_weak_eq weak1
    end
    it 'should return false for the different weak tags' do
      expect(weak1).to_not be_weak_eq weak2
    end
    it 'should return true for tags that are same but one is weak and one is strong' do
      expect(weak1).to be_weak_eq strong1
      expect(strong1).to be_weak_eq weak1
    end
    it 'should return true for the same strong tags' do
      expect(strong1).to be_weak_eq strong1
    end
  end

  describe '#==' do
    it 'should return true for the same weak tags' do
      expect(weak1).to be == weak1
    end
    it 'should return false for the different weak tags' do
      expect(weak1).to_not be == weak2
    end
    it 'should return false for tags that are same but one is weak and one is strong' do
      expect(weak1).to_not be == strong1
      expect(strong1).to_not be == weak1
    end
    it 'should return true for the same strong tags' do
      expect(strong1).to be == strong1
    end
  end

  describe '#===' do
    it 'should return true for the same weak tags' do
      expect(weak1).to be === weak1
    end
    it 'should return false for the different weak tags' do
      expect(weak1).to_not be === weak2
    end
    it 'should return true for the same tags when the receiver is weak and the other is strong' do
      expect(weak1).to be === strong1
    end
    it 'should return false for the same tags when the receiver is strong and the other is weak' do
      expect(strong1).to_not be === weak1
    end
    it 'should return true for the same strong tags' do
      expect(strong1).to be === strong1
    end
  end

end
