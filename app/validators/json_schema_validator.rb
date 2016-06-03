# validates a hash with a given json-schema file
class JSONSchemaValidator
  attr_reader :params, :schema_file

  # `params` should be any json serializable hash
  def initialize(params, schema_file = nil)
    @params = params
    @schema_file = schema_file
  end

  def validate
    @errors = JSON::Validator.fully_validate(
      schema, params,
      errors_as_objects: true
    )
    @errors.empty?
  end

  alias valid? validate

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

  # Parse each error message
  # return:
  #    - list with 2 values: [property_name, error_message]
  def parse_error(err)
    if err[:failed_attribute] == 'Required'
      parse_error_for_required_attr(err)
    else
      parse_error_default(err)
    end
  end

  def parse_error_for_required_attr(err)
    # extract the property name
    prop_name = err[:message].match(/required property of '(.*?)'/)[1]
    [prop_name, "The property '#{prop_name}' is required"]
  end

  def parse_error_default(err)
    msg = err[:message].gsub(/ in schema .*$/, '').gsub('#/', '')
    # extract the property name
    prop_name = msg.match(/The property '(\w+)?' /)[1]
    msg = schema_error_msg(prop_name) || msg

    [prop_name, msg]
  end

  def schema_error_msg(prop)
    parsed_schema['properties'].fetch(prop, {})['error']
  end

  def schema
    @schema ||= File.read(schema_file)
  end

  def parsed_schema
    @parsed_schema ||= JSON.parse schema
  end
end
