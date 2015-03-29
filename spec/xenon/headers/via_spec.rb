require 'xenon/headers/via'

describe Xenon::Headers::Via do

  context '::parse' do
    it 'can parse a header with an IPv4 proxy' do
      via = Xenon::Headers::Via.parse('HTTP/1.1 192.168.0.1')
      expect(via.proxies.size).to eq(1)
      expect(via.proxies[0].protocol).to eq(Xenon::Protocol::HTTP_11)
      expect(via.proxies[0].host).to eq(IPAddr.new('192.168.0.1', Socket::AF_INET))
      expect(via.proxies[0].port).to be_nil
      expect(via.proxies[0].comment).to be_nil
    end

    it 'can parse a header with an IPv4 proxy and port' do
      via = Xenon::Headers::Via.parse('HTTP/1.1 192.168.0.1:443')
      expect(via.proxies.size).to eq(1)
      expect(via.proxies[0].protocol).to eq(Xenon::Protocol::HTTP_11)
      expect(via.proxies[0].host).to eq(IPAddr.new('192.168.0.1', Socket::AF_INET))
      expect(via.proxies[0].port).to eq(443)
      expect(via.proxies[0].comment).to be_nil
    end

    it 'can parse a header with an IPv6 proxy' do
      via = Xenon::Headers::Via.parse('HTTP/1.1 [3ffe:505:2::1]')
      expect(via.proxies.size).to eq(1)
      expect(via.proxies[0].protocol).to eq(Xenon::Protocol::HTTP_11)
      expect(via.proxies[0].host).to eq(IPAddr.new('3ffe:505:2::1', Socket::AF_INET6))
      expect(via.proxies[0].port).to be_nil
      expect(via.proxies[0].comment).to be_nil
    end

    it 'can parse a header with an pseudonym proxy' do
      via = Xenon::Headers::Via.parse('HTTP/1.1 hiddenproxy')
      expect(via.proxies.size).to eq(1)
      expect(via.proxies[0].protocol).to eq(Xenon::Protocol::HTTP_11)
      expect(via.proxies[0].host).to eq('hiddenproxy')
      expect(via.proxies[0].port).to be_nil
      expect(via.proxies[0].comment).to be_nil
    end
  end

end
