require 'active_record'
require_relative 'app/api/base'

use ActiveRecord::ConnectionAdapters::ConnectionManagement

run API::Base
