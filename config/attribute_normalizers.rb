AttributeNormalizer.configure do |config|
  config.normalizers[:downcase] = lambda do |value, _|
    value.is_a?(String) ? value.downcase : value
  end

  config.normalizers[:remove_spaces] = lambda do |value, _|
    value.is_a?(String) ? value.gsub(/[[:space:]]/, '') : value
  end

  config.normalizers[:underscore] = lambda do |value, _|
    value.is_a?(String) ? value.underscore : value
  end

  config.default_normalizers = :blank, :strip
end
