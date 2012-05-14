class TemplateDir

  CONFIG_FILE = '.template.rb'

  attr_reader :base_dir,
              :parent

  def initialize(base_dir)
    raise "Template directory does not exist: #{base_dir}" unless Dir.exist?(base_dir)
    @base_dir = base_dir
    @config = TemplateDir::get_template_config(base_dir)
    parent = @config[:parent]
    @parent = TemplateDir.new(path_to(parent)) if parent
  end

  def to_s
    @base_dir
  end

  def get_required(key)
    value = @config[key]
    raise "No #{key} found in #@config" if value.nil?
    value
  end

  def filtered_files
    all_files.select { |f| filtered_file?(f) }
  end

  def non_filtered_files
    all_files.reject { |f| filtered_file?(f) }
  end

  def all_files
    Dir.glob("#@base_dir/**/*", File::FNM_DOTMATCH).
            reject { |file| special_file?(file) }.
            reject { |file| File.directory?(file) }
  end

  private

  def filtered_file?(file)
    patterns = @config[:filter]
    if patterns.nil?
      patterns = [] # XXX: use default values
    end
    patterns.any? { |pattern| File.fnmatch?(pattern, file) }
  end

  SPECIAL_FILES = ['.', '..', TemplateDir::CONFIG_FILE]

  def special_file?(file)
    SPECIAL_FILES.include?(File.basename(file))
  end

  def path_to(relative_path)
    File.absolute_path(relative_path, @base_dir)
  end

  def self.get_template_config(template_dir)
    my_config = {}
    my_config_file = File.join(template_dir, TemplateDir::CONFIG_FILE)
    if File.exist?(my_config_file)
      my_config = eval(IO.read(my_config_file))
    end

    parent_config = {}
    parent = my_config[:parent]
    if parent
      parent_config = get_template_config(File.absolute_path(parent, template_dir))
    end

    # TODO: default values (e.g. :filter => [])
    combined = {}
    combined.merge!(parent_config)
    combined.merge!(my_config)
    combined
  end
end
