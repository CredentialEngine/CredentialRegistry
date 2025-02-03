namespace :swagger do
  desc 'Install swagger'
  task install: :cer_environment do
    `bin/install_swagger`
  end

  desc 'Build swagger json'
  task build: :cer_environment do
    require 'swagger_docs'

    path = File.expand_path('../../tmp/swagger.json', __dir__)
    File.open(path, 'w') do |f|
      puts "Writing swagger definition to #{path}"
      definition = Swagger::Blocks.build_root_json [MR::SwaggerDocs]
      f.write definition.to_json
    end
  end
end
