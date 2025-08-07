RSpec::Matchers.define :be_bnode do
  match do |actual|
    return false unless actual.is_a?(String)
    return false unless actual.start_with?('_:')

    UUID.validate(actual[2..actual.size - 1]).present?
  end

  description do
    "be a valid bnode (i.e. a UUID with '_:' prefix)"
  end

  failure_message do |actual|
    if !actual.is_a?(String)
      "expected #{actual.inspect} to be a String, but it was #{actual.class}"
    elsif !actual.start_with?('_:')
      "expected #{actual.inspect} to start with '_:', but it starts with '#{actual[0..1]}'"
    else
      uuid_part = actual[2..actual.size - 1]
      # rubocop:todo Layout/LineLength
      "expected #{actual.inspect} to have a valid UUID after the '_:' prefix, but '#{uuid_part}' is not a valid UUID"
      # rubocop:enable Layout/LineLength
    end
  end

  failure_message_when_negated do |actual|
    "expected #{actual.inspect} not to be a bnode, but it was"
  end
end
