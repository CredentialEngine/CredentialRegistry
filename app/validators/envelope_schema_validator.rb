# validates a params request against the envelope json-schema
class EnvelopeSchemaValidator
  attr_reader :params

  # `params` should be any json serializable hash
  def initialize(params)
    @params = params
  end

  def valid?
    @errors = JSON::Validator.fully_validate(
      schema, params,
      errors_as_objects: true
    )
    @errors.empty?
  end

  # parse validation errors to be more readable
  # return:
  #    - [Hash] with the properties/messages pairs if has errors
  #    - [nil]  if has no errors
  def errors
    return nil if @errors.empty?

    errs = @errors.map { |err| parse_error err }
    Hash[*errs.flatten].with_indifferent_access
  end

  private

  def parse_error(err)
    if err[:failed_attribute] == 'Required' # for required keys
      # extract the property name
      prop_name = err[:message].match(/required property of '(.*?)'/)[1]
      msg = "The property '#{prop_name}' is required"

    else # for other failed attrs
      msg = err[:message].gsub(/ in schema .*$/, '').gsub('#/', '')
      # extract the property name
      prop_name = msg.match(/The property '(.*)?'/)[1]

    end
    [prop_name, msg]
  end

  def schema
    File.read(File.expand_path('../../schemas/envelope.json', __FILE__))
  end
end
