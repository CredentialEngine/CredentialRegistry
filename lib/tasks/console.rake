desc 'Starts an interactive console.'
task console: :cer_environment do
  require 'irb'
  ARGV.clear
  IRB.start
end
