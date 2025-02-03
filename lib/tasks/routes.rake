desc 'API Routes'
task routes: [:cer_environment] do
  API::Base.routes.each do |api|
    method = api.request_method.ljust(10)
    path = api.path
    puts "     #{method} #{path}"
  end
end
