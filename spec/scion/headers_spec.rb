require 'scion/headers'

describe Scion::Headers::Accept do

  context '::parse' do

    it 'can parse things' do

      puts Scion::Headers::Accept.parse('application/json, application/xml')

    end

  end

end