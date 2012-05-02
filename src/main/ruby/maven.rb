class MavenArtifact

  attr_accessor :group_id, :artifact_id, :version, :packaging, :classifier

  def initialize(artifact)
    elements = artifact.split(':')
    @group_id = elements[0]
    @artifact_id = elements[1]
    @version = elements[2]
    @packaging = elements.fetch(3, 'jar')
    @classifier = elements.fetch(4, '')
  end

  def path(repository_path=nil)
    if classifier != ''
      suffix = '-' + classifier
    else
      suffix = ''
    end
    filename = artifact_id + '-' + version + suffix + '.' + packaging
    relative_path = File.join(group_id.gsub('.', '/'), artifact_id, version, filename)
    if repository_path != nil
      File.join(repository_path, relative_path)
    else
      relative_path
    end
  end

  def simple_name
    artifact_id + '.' + packaging
  end
end
