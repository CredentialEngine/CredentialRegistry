# Workaround class that allows mounting the same API to different routes.
# Check out https://github.com/ruby-grape/grape/issues/570
class MountableAPI
  def self.api_class
    Class.new(Grape::API).tap do |klass|
      klass.instance_eval(&@proc)
    end
  end

  def self.mounted(&block)
    @proc = block
  end
end
