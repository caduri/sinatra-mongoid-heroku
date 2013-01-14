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
  field :deploy_key,    :type => String

  def request_info
    if self.params
      [self.params["request_method"], self.url].compact.join(" ")
    else
      "UNKNOWN #{self.url}"
    end
  end

  def location
    [self.component, self.action].compact.join("#")
  end
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
    if params[:component]
      case params[:component]
      when "shai"
        redirect "http://www.youtube.com/watch?v=WIK0h3xo9O0"
      when "avner"
        redirect "http://www.youtube.com/watch?v=LkwGlVztiuU"
      when "nir"
        redirect "http://www.youtube.com/watch?v=Vyt0TuqlReg"
      when "moshe"
        redirect "http://www.youtube.com/watch?v=ILRe9dHyby8"
      when "yogev"
        redirect "http://www.freegaytube.com/"
      else
      end
    end

    page = (params[:page] || 1).to_i
    params.delete(:page)
    search_params = params.dup
    search_params.delete_if { |key, val| val.to_s == ""}
    search_params["open"] != "on" ? search_params["open"] = false : search_params["open"] = true
    @errors = ErrorReport.where(search_params).limit(20).skip((page - 1) * 20).desc("_id").all
    erb :index
  end

  get "/close/:id" do
    @error = ErrorReport.find(params[:id])
    if @error
      @error.open = false
      @error.save!
    end
    redirect request.referer
  end
end

class Public < Sinatra::Base

  set :static, true

  get "/" do
    status 401
  end

  # Controllers
  post '/notifier_api/v2/notices/' do
    raw = request.body.read
    #$stdout.puts raw.inspect
    parsed = Hpricot::XML(raw)
    server_env = parsed.at("server-environment")
    env_name = server_env.at("environment-name").inner_html rescue ""
    host = server_env.at("hostname").inner_html rescue ""
    error_elm = parsed.at("error")
    request_elm = parsed.at("request")

    backtrace = parsed.at("backtrace")
    if backtrace
      backtrace = (backtrace/"line").collect { |e| [e.attributes["file"], e.attributes["number"]].join(":") }.slice(0...5)
    end

    $stdout.puts backtrace.inspect
    component = request_elm.at("component").inner_html rescue ""
    action = request_elm.at("action").inner_html rescue ""
    url = request_elm.at("url").inner_html rescue ""
    error_class = error_elm.at("class").inner_html rescue ""
    error_message = error_elm.at("message").inner_html rescue ""
    
    params = {}

    if request_elm
      (request_elm/"var").each do |var|
        params[var.attributes["key"].gsub(".", ' ').downcase] = var.inner_html unless var.attributes["key"].include?("rack.")
      end
    end
    begin
      ErrorReport.create!(:env => env_name,
                          :host => host,
                          :url => url,
                          :error_class => error_class,
                          :error_message => error_message,
                          :component => component,
                          :action => action,
                          :backtrace => backtrace.join("<br/>"),
                          :params => params)
      status 201
    rescue Exception => e
      puts "ERROR: #{e}"
      status 500
    end
  end
end

