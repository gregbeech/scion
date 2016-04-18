require_relative '../spec_helper'
require 'xenon/routing/route_directives'

describe Xenon::Routing::RouteDirectives, type: :xenon do
  route do
    complete :ok, 'hi'
  end

  it do
    expect{ get '/' }.to have_http_status 200
  end
end
