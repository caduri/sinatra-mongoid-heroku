require 'sinatra'
require 'sinatra/base'
require 'thin'
require 'mongoid'

Mongoid.load!("config/mongoid.yml")

# This model I copypasted from somewhere.
# It's just to check everything is fine.

# Models
class ErrorReport
    include Mongoid::Document
    include Mongoid::Timestamps

    field :env,           :type => String
    field :error_class,   :type => String
    field :error_message, :type => String
    field :params,        :type => Hash
end

get "/" do
  "Fuck you"
end

# Controllers
post '/errors' do
  
end


