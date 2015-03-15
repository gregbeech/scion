require 'scion/headers/authorization'

describe Scion::Headers::Authorization do

  context '::parse' do
    it 'can parse Basic credentials' do
      header = Scion::Headers::Authorization.parse('Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ==')
      expect(header.credentials.class).to eq(Scion::BasicCredentials)
      expect(header.credentials.username).to eq('Aladdin')
      expect(header.credentials.password).to eq('open sesame')
    end

    it 'can parse Digest credentials' do
      header = Scion::Headers::Authorization.parse('Digest username="Mufasa"' +
        ', realm="testrealm@host.com"' +
        ', nonce="dcd98b7102dd2f0e8b11d0f600bfb0c093"' +
        ', uri="/dir/index.html"' +
        ', qop=auth' +
        ', nc=00000001' +
        ', cnonce="0a4f113b"' +
        ', response="6629fae49393a05397450978507c4ef1"' +
        ', opaque="5ccc069c403ebaf9f0171e9517f40e41"')
      expect(header.credentials.class).to eq(Scion::GenericCredentials)
      expect(header.credentials.scheme).to eq('Digest')
      expect(header.credentials.token).to eq(nil)
      expect(header.credentials.params).to eq(
        'username' => 'Mufasa',
        'realm' => 'testrealm@host.com',
        'nonce' => 'dcd98b7102dd2f0e8b11d0f600bfb0c093',
        'uri' => '/dir/index.html',
        'qop' => 'auth',
        'nc' => '00000001',
        'cnonce' => '0a4f113b',
        'response' => '6629fae49393a05397450978507c4ef1',
        'opaque' => '5ccc069c403ebaf9f0171e9517f40e41')
    end

    it 'can parse Bearer credentials' do
      header = Scion::Headers::Authorization.parse('Bearer eyJhbGciOiJub25lIn0.eyJpc3MiOiJqb2UiLA0KICJleHAiOjEzMDA4MTkzODAsDQogImh0dHA6Ly9leGFtcGxlLmNvbS9pc19yb290Ijp0cnVlfQ.')
      expect(header.credentials.class).to eq(Scion::GenericCredentials)
      expect(header.credentials.scheme).to eq('Bearer')
      expect(header.credentials.token).to eq('eyJhbGciOiJub25lIn0.eyJpc3MiOiJqb2UiLA0KICJleHAiOjEzMDA4MTkzODAsDQogImh0dHA6Ly9leGFtcGxlLmNvbS9pc19yb290Ijp0cnVlfQ.')    
      expect(header.credentials.params).to eq({})
    end
  end

end