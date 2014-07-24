require 'sinatra'
require 'json'
require 'bundler'

Dir["./lib/services/*.rb"].each { |file| require file }

post '/payload' do
  payload_body = request.body.read
  verify_signature(payload_body)
  GithubWatcher::WebHook.dispatcher(payload_body)
end

def verify_signature(payload_body)
  encrypted_payload = OpenSSL::HMAC.hexdigest(
    OpenSSL::Digest.new('sha1'),
    ENV['GITHUB_SECRET_TOKEN'],
    payload_body
  )
  signature = 'sha1=' + encrypted_payload
  unless Rack::Utils.secure_compare(signature, request.env['HTTP_X_HUB_SIGNATURE'])
    return halt 500, "Signatures didn't match!"
  end
end
