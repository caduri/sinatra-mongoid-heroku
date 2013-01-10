require './myapp'

use Rack::Static, :urls => ["/images", "/bootstrap"], :root => "public"
run Rack::URLMap.new({
  "/" => Public,
  "/images" => Public,
  "/notifier_api" => Public,
  "/errors/" => Protected,
})
