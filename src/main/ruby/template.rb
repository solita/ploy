require 'erb'

class Hash
  def to_binding(object = Object.new)
    object.instance_eval("def binding_for(#{keys.join(",")}) binding end")
    object.binding_for(*values)
  end
end

class Template
  def initialize(template)
    @template = ERB.new(template)
  end

  def interpolate(replacements = {})
    @template.result(replacements.to_binding)
  end
end
