# Adds a method for formatting payload contents.
module PayloadFormatter
  def format_payload(payload)
    new_payload = {}
    new_payload['@context'] = payload.delete('@context')
    new_payload['@id'] = payload.delete('@id')
    new_payload['@graph'] = payload.delete('@graph')
    payload.each { |k, v| new_payload[k] = v }
    new_payload
  end
end
