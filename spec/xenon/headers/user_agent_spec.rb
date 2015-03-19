require 'xenon/headers/user_agent'

describe Xenon::Headers::UserAgent do

  context '::parse' do
    it 'can parse a user agent with a product name' do
      header = Xenon::Headers::UserAgent.parse('Mozilla')
      expect(header.products.size).to eq(1)
      expect(header.products[0].name).to eq('Mozilla')
      expect(header.products[0].version).to be_nil
      expect(header.products[0].comment).to be_nil
    end

    it 'can parse a user agent with a product name and version' do
      header = Xenon::Headers::UserAgent.parse('Mozilla/5.0')
      expect(header.products.size).to eq(1)
      expect(header.products[0].name).to eq('Mozilla')
      expect(header.products[0].version).to eq('5.0')
      expect(header.products[0].comment).to be_nil
    end

    it 'can parse a user agent with a product name and comment' do
      header = Xenon::Headers::UserAgent.parse('Mozilla (Macintosh; Intel Mac OS X 10_10_2)')
      expect(header.products.size).to eq(1)
      expect(header.products[0].name).to eq('Mozilla')
      expect(header.products[0].version).to be_nil
      expect(header.products[0].comment).to eq('Macintosh; Intel Mac OS X 10_10_2')
    end

    it 'can parse a user agent with a product name, version and comment' do
      header = Xenon::Headers::UserAgent.parse('Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_2)')
      expect(header.products.size).to eq(1)
      expect(header.products[0].name).to eq('Mozilla')
      expect(header.products[0].version).to eq('5.0')
      expect(header.products[0].comment).to eq('Macintosh; Intel Mac OS X 10_10_2')
    end

    it 'can parse a user agent with multiple comments' do
      header = Xenon::Headers::UserAgent.parse('Mozilla/5.0 (Macintosh) (Intel Mac OS X 10_10_2)')
      expect(header.products.size).to eq(2)
      expect(header.products[0].name).to eq('Mozilla')
      expect(header.products[0].version).to eq('5.0')
      expect(header.products[0].comment).to eq('Macintosh')
      expect(header.products[1].name).to be_nil
      expect(header.products[1].version).to be_nil
      expect(header.products[1].comment).to eq('Intel Mac OS X 10_10_2')
    end

    it 'can parse a typical Chrome user agent' do
      header = Xenon::Headers::UserAgent.parse('Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2272.89 Safari/537.36')
      expect(header.products.size).to eq(4)
      expect(header.products[0].name).to eq('Mozilla')
      expect(header.products[0].version).to eq('5.0')
      expect(header.products[0].comment).to eq('Macintosh; Intel Mac OS X 10_10_2')
      expect(header.products[1].name).to eq('AppleWebKit')
      expect(header.products[1].version).to eq('537.36')
      expect(header.products[1].comment).to eq('KHTML, like Gecko')
      expect(header.products[2].name).to eq('Chrome')
      expect(header.products[2].version).to eq('41.0.2272.89')
      expect(header.products[2].comment).to be_nil
      expect(header.products[3].name).to eq('Safari')
      expect(header.products[3].version).to eq('537.36')
      expect(header.products[3].comment).to be_nil
    end
  end

end