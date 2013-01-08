require 'sinatra'
require 'sinatra/base'
require 'thin'
require 'mongoid'
require 'hpricot'

Mongoid.load!("config/mongoid.yml")

# This model I copypasted from somewhere.
# It's just to check everything is fine.

# Models
class ErrorReport
    include Mongoid::Document
    include Mongoid::Timestamps

    field :env,           :type => String
    field :host,          :type => String
    field :error_class,   :type => String
    field :error_message, :type => String
    field :params,        :type => Hash
    field :raw,           :type => String
end

get "/" do
  status 404
end

get "/jshdvbn2846shdhhhdsj" do
  page = params[:page].to_i
  @errors = ErrorReport.limit(20).skip(20 * page).desc("_id").all
  @errors
  erb :index
end

# Controllers
post '/notifier_api/v2/notices/' do
  $stdout.puts params.inspect
  raw = request.body.read
  parsed = Hpricot::XML(raw)
  server_env = parsed.at("server-environment")
  env_name = server_env.at("environment-name").inner_html
  host = server_env.at("hostname").inner_html
  error_elm = parsed.at("error")
  error_class = error_elm.at("class").inner_html
  error_message = error_elm.at("message").inner_html
  
  ErrorReport.create!(:env => env_name,
                      :host => host,
                      :error_class => error_class,
                      :error_message => error_message,
                      :raw => raw)
  status 201
end


