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
    field :url,           :type => String
    field :host,          :type => String
    field :error_class,   :type => String
    field :error_message, :type => String
    field :params,        :type => Hash
    field :raw,           :type => String
    field :backtrace,     :type => String
    field :component,     :type => String
    field :action,        :type => String
    field :open,           :type => Boolean, :default => true
end

class Protected < Sinatra::Base
  use Rack::Auth::Basic, "Protected Area" do |username, password|
    username == 'fiverr' && password == 'HaifaalufA'
  end

  set :static, true

  get "/:id" do
    @error = ErrorReport.find(params[:id])
    erb :show
  end

  get "/" do
    page = (params[:page] || 1).to_i
    @errors = ErrorReport.limit(20).skip((page - 1) * 20).desc("_id").all
    erb :index
  end

end

class Public < Sinatra::Base

  set :static, true

  get "/" do
    status 401
  end

  # Controllers
  post '/notifier_api/v2/notices/' do
    $stdout.puts params.inspect
    raw = request.body.read
    parsed = Hpricot::XML(raw)
    server_env = parsed.at("server-environment")
    env_name = server_env.at("environment-name").inner_html rescue ""
    host = server_env.at("hostname").inner_html rescue ""
    error_elm = parsed.at("error")
    request_elm = parsed.at("request")

    backtrace = error_elm.at("backtrace").inner_html rescue ""  
    component = request_elm.at("component").inner_html rescue ""
    action = request_elm.at("action").inner_html rescue ""
    url = request_elm.at("url").inner_html rescue ""
    error_class = error_elm.at("class").inner_html rescue ""
    error_message = error_elm.at("message").inner_html rescue ""
    
    params = {}
    (request_elm/"var").each do |var|
      params[var.attributes["key"]] = var.inner_html
    end
    begin
      ErrorReport.create!(:env => env_name,
                          :host => host,
                          :error_class => error_class,
                          :error_message => error_message,
                          :component => component,
                          :action => action,
                          :backtrace => backtrace,
                          :params => params)
      status 201
    rescue Exception => e
      puts "ERROR: #{e}"
      status 500
    end
  end
end

