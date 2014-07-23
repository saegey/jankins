require 'sinatra'
require 'json'
require 'bundler'

Dir["./lib/services/*.rb"].each { |file| require file }

post '/payload' do
  GithubWatcher::WebHook.dispatcher(request.body.read)
end
