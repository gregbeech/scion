require 'scion'

class MyApp < Scion::Api

  def route
    # path '/' do
      get do        
    #     query_hash do |query|
        # extract -> ctx { ctx.request.request_method } do |m|
          complete 200, { hello: 'World' }#.merge(query)
        # end
          # reject Scion::Rejection.new(Scion::Rejection::METHOD, { supported: 'STUFF' })
        end
      # end |
      # post do
      # 	form_hash do |form|
      #     respond_with_header Scion::Headers::Raw.new('Location', "/#{form['id']}") do
      #       complete 201, { created: 'OK' }.merge(form)
      #     end
      #   end
      # end
    # end
    # path_prefix '/users' do
    #   path_end do
    #     get do
    #       complete 200, [{ user_id: 123 }, { user_id: 456 }]
    #     end
    #   end
    #   path '/([0-9]+)' do |user_id|
    #     get do
    #       complete 200, { user_id: user_id }
    #     end
    #   end
    # end
  end

end
