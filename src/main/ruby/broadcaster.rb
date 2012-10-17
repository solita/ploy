class Broadcaster

  def initialize(*targets)
    @targets = targets
  end

  def method_missing(method_name, *args)
    @targets.each { |target| target.send(method_name, *args) }
  end
end
