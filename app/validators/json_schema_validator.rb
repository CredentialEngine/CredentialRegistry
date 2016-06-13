# Generic JSON Schema validator
class JSONSchemaValidator
  attr_reader :params, :schema_name

  # `params` should be any json serializable hash
  def initialize(params, schema_name = nil)
    @params = params
    @schema_name = schema_name
  end

  def validate
    @errors = JSON::Validator.fully_validate(
      schema, params,
      errors_as_objects: true
    )
    @errors.empty?
  end

  alias valid? validate

  def invalid?
    !valid?
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

  def error_messages
    errors ? errors.map { |prop, msg| "#{prop} : #{msg}" } : []
  end

  def schema
    @schema ||= begin
      content = File.read(schema_file)
      JSON.parse content
    end
  end

  def schema_file
    File.expand_path("../../schemas/#{schema_name}.json", __FILE__)
  end

  def schema_exist?
    File.exist?(schema_file)
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
    schema['properties'].fetch(prop, {})['error']
  end
end
