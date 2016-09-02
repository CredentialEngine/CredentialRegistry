
namespace :swagger do
  desc 'Build swagger json'
  task build: [:environment] do
    require 'swagger_docs'

    path = File.expand_path('../../../public/swagger.json', __FILE__)
    File.open(path, 'w') do |f|
      puts "Writing swagger definition to #{path}"
      definition = Swagger::Blocks.build_root_json [MR::SwaggerDocs]
      f.write definition.to_json
    end
  end
end
