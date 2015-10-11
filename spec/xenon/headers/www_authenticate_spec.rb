require 'xenon/headers/www_authenticate'

describe Xenon::Headers::WwwAuthenticate do

  context '::parse' do

    it 'can parse a Basic challenge with a realm' do
      header = Xenon::Headers::WwwAuthenticate.parse('Basic realm="simple"')
      expect(header.challenges.size).to eq(1)
      expect(header.challenges[0].auth_scheme).to eq('Basic')
      expect(header.challenges[0].realm).to eq('simple')
    end

    it 'can parse a Digest challenge with a realm' do
      header = Xenon::Headers::WwwAuthenticate.parse('Digest realm="testrealm@host.com", qop="auth,auth-int", nonce="dcd98b7102dd2f0e8b11d0f600bfb0c093", opaque="5ccc069c403ebaf9f0171e9517f40e41"')
      expect(header.challenges.size).to eq(1)
      expect(header.challenges[0].auth_scheme).to eq('Digest')
      expect(header.challenges[0].realm).to eq('testrealm@host.com')
      expect(header.challenges[0].qop).to eq('auth,auth-int')
      expect(header.challenges[0].nonce).to eq('dcd98b7102dd2f0e8b11d0f600bfb0c093')
      expect(header.challenges[0].opaque).to eq('5ccc069c403ebaf9f0171e9517f40e41')
    end

    it 'can parse a custom challenge' do
      header = Xenon::Headers::WwwAuthenticate.parse('Newauth realm="apps", type=1, title="Login to \"apps\""')
      expect(header.challenges.size).to eq(1)
      expect(header.challenges[0].auth_scheme).to eq('Newauth')
      expect(header.challenges[0].realm).to eq('apps')
      expect(header.challenges[0].type).to eq('1')
      expect(header.challenges[0].title).to eq('Login to "apps"')
    end

    it 'can parse multiple challenges' do
      header = Xenon::Headers::WwwAuthenticate.parse('Digest realm="testrealm@host.com", qop="auth,auth-int", nonce="dcd98b7102dd2f0e8b11d0f600bfb0c093", opaque="5ccc069c403ebaf9f0171e9517f40e41", Basic realm="simple", Newauth realm="apps", type=1, title="Login to \"apps\""')
      expect(header.challenges.size).to eq(3)
      expect(header.challenges[0].auth_scheme).to eq('Digest')
      expect(header.challenges[1].auth_scheme).to eq('Basic')
      expect(header.challenges[2].auth_scheme).to eq('Newauth')
    end


  end
end