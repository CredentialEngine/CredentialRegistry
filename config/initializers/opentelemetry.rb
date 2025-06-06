require "opentelemetry/sdk"
require "opentelemetry/instrumentation/all"

ENV['OTEL_TRACES_EXPORTER'] = 'http://localhost:4318'
OpenTelemetry::SDK.configure do |c|
  c.use_all
end