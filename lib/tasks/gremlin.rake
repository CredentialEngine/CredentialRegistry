namespace :gremlin do
  def rake_root
    Rake.application.original_dir
  end

  def gremlin_path
    File.join(rake_root, 'db', 'gremlin', 'server')
  end

  def gremlin_cmd(*cmds)
    ([File.join(gremlin_path, 'bin', 'gremlin-server.sh')] + cmds).join(' ')
  end

  desc 'Installs Gremlin Server.'
  task(:install) { exec File.join(rake_root, 'bin', 'install_gremlin_server') }

  desc 'Installs Gremlin Console.'
  task(:install_console) { exec File.join(rake_root, 'bin', 'install_gremlin_console') }

  desc 'Starts Gremlin Server.'
  task :start, [:config] do |_, args|
    config = args[:config] || 'ro'
    config_path = File.join(gremlin_path, 'conf', "#{config}.yaml")
    system("GREMLIN_YAML=#{config_path} #{gremlin_cmd('start')}")
  end

  desc 'Stops Gremlin Server.'
  task(:stop) { system(gremlin_cmd('stop')) }

  desc 'Imports the entire database into the Neo4j instance backing Gremlin Server.'
  task :import do
    require File.expand_path('../../../config/environment', __FILE__)
    require 'neo4j_import_gremlin'

    session = Neo4j::Session.open(:server_db, ENV['NEO4J_GREMLIN_URL'])
    Neo4jImportGremlin.bulk_import(session)
  end

  desc 'Prepares the Neo4j instance for Gremlin usage. Only needs to be run once.'
  task :init_neo4j do
    # Start Tinkerpop in writable mode, so that it may create any needed objects.
    # We have to do this once before running in read-only mode.
    Rake::Task[:'gremlin:start'].invoke('rw')
    sleep 10
    Rake::Task[:'gremlin:stop'].invoke('rw')
  end

  desc 'Starts Gremlin Console.'
  task :console do
    console_path = File.join(rake_root, 'db', 'gremlin', 'console', 'bin', 'gremlin.sh')
    script_path = File.join(rake_root, 'db', 'gremlin-config', 'console', 'console.groovy')
    exec console_path, '-i', script_path
  end
end
