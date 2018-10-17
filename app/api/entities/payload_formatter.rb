# Adds a method for formatting payload contents.
module PayloadFormatter
  def format_payload(payload)
    new_payload = {}
    ['@context', '@id', '@graph'].each do |key|
      val = payload.delete(key)
      new_payload[key] = val if val.present?
    end
    payload.each { |k, v| new_payload[k] = v }
    new_payload
  end

  module_function :format_payload
end
