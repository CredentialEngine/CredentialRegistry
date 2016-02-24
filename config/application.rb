$LOAD_PATH.unshift(File.dirname(__FILE__))
%w(models api/v1 api).each do |load_path|
  $LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'app', load_path))
end

require 'boot'
Bundler.require :default, ENV['RACK_ENV']
require 'base'

# Main application module
module LearningRegistry
  def self.env
    ENV['RACK_ENV']
  end
end
