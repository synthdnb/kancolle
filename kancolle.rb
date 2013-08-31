require 'sinatra'
require 'rest_client'
require 'haml'

set :environment, :production
set :bind, '0.0.0.0'
set :server, :thin


get '/' do
  haml :login
end

post '/' do
  id = params[:id]
  pw = params[:password]

  cookies = {}
  proc = Proc.new {|response, request, result, &block|
    cookies.merge!(response.cookies)
    if [301, 302, 307].include? response.code
      response.follow_redirection(request, result, &block)
    else
      response.return!(request, result, &block)
    end
  }
  page = RestClient.get('https://www.dmm.com/my/-/login/', &proc);
  token = page.match(/^.*name="token"\s+value="(\w+)".*$/)[1]
  auth = {
    login_id: id,
    password: pw,
    token: token,
    save_login_id: 0,
    save_password: 0, 
    path: nil
  }

  RestClient.post('https://www.dmm.com/my/-/login/auth/', auth, cookies: cookies, &proc);
  resp2 = RestClient.get('http://www.dmm.com/netgame/social/-/gadgets/=/app_id=854854/', cookies: cookies, &proc);
  game_url = resp2.chars.select{|i| i.valid_encoding?}.join.match(/^.*URL.*"(.*osapi.*)".*$/)[1]
  redirect game_url
  
end
