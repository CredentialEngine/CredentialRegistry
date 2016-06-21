# Generic JSON Schema validator
class JSONSchemaValidator
  attr_reader :params, :schema_name

  # Params:
  #  - params: [Hash] should be any json serializable hash
  #  - schema_name: [String|Symbol] the schema-json name, corresponding to the
  #                 json file inside the schemas folder.
  #                 I.e: if you pass 'something', it will load the
  #                      'schemas/something.json' schema)
  def initialize(params, schema_name = nil)
    @params = params
    @schema_name = schema_name
  end

  # Validate params with the defined schema
  # Return: [Boolean]
  def validate
    @errors = JSON::Validator.fully_validate(
      schema_file, params,
      errors_as_objects: true
    )
    @errors.empty?
  end

  alias valid? validate

  def invalid?
    !valid?
  end

  # Parse validation errors to be more readable
  # Return:
  #    - [Hash] with the properties/messages pairs if has errors
  #    - [nil]  if has no errors
  def errors
    return nil if @errors.nil? || @errors.empty?

    errs = @errors.map { |err| parse_error err }
    Hash[*errs.flatten].with_indifferent_access
  end

  # Full errors messages (property name + message)
  # Return: [Array]
  def error_messages
    errors ? errors.map { |prop, msg| "#{prop} : #{msg}" } : []
  end

  def schema
    @schema ||= JSON.parse schema_content
  end

  def public_schema(req)
    @public_schema ||= begin
      # change refs to be public uris
      content = schema_content.gsub(
        # from: "$ref": "json_ld.json"
        /\"\$ref\": \"(.*)\.json\"/,
        # to:   "$ref": "http://myurl.com/api/schemas/json_ld"
        "\"$ref\": \"#{req.base_url}/api/schemas/\\1\""
      )
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

  # schema file content
  # Return: [String]
  def schema_content
    @schema_content ||= File.read(schema_file)
  end

  # Parse each error message
  # Return: [List] list with 2 values: [property_name, error_message]
  def parse_error(err)
    if err[:errors]
      err[:errors].values.flatten.map { |nested_err| parse_error(nested_err) }
    elsif err[:failed_attribute] == 'Required'
      parse_error_for_required_attr(err)
    else
      parse_error_default(err)
    end
  end

  def parse_error_for_required_attr(err)
    # extract the property name
    prop_name = err[:message].match(/required property of '(.*?)'/)[1]
    [prop_name, 'is required']
  end

  def parse_error_default(err)
    err_msg = err[:message].gsub(/ in schema .*$/, '').gsub('#/', '')
    prop_name = err_msg.match(/The property '(@?\w+).*' /)[1]

    # parse err message
    #   from: "The property 'bla' with value "ble" did not match the value 42"
    #   to:   "did not match the value 42"
    parsed_msg = err_msg.match(/^The property '.*' .* (did not .*)$/)[1]
    message = schema_error_msg(prop_name) || parsed_msg

    [prop_name, message]
  end

  # Get custom error messages defined on the schema
  # Return: [String|nil] the err message or nil if does not exist
  def schema_error_msg(prop)
    msg = schema.fetch('properties', {}).fetch(prop, {})['error']
    msg || begin
      schema.fetch('definitions', {}).values.map do |attrs|
        attrs.fetch('properties', {}).fetch(prop, {})['error']
      end.first
    end
  end
end
