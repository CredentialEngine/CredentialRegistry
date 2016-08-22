desc 'API Routes'
task :routes do
  API::Base.routes.each do |api|
    method = api.request_method.ljust(10)
    path = api.path
    puts "     #{method} #{path}"
  end
end
