require 'rexml/document'

class MavenArtifact

  attr_reader :group_id, :artifact_id, :version, :packaging, :classifier

  def initialize(artifact)
    elements = artifact.split(':')
    @group_id = elements[0]
    @artifact_id = elements[1]
    @version = elements[2]
    @packaging = elements.fetch(3, 'jar')
    @classifier = elements.fetch(4, '')
  end

  def path(repository_path=nil)
    directory = File.join(group_id.gsub('.', '/'), artifact_id, version)
    directory = File.join(repository_path, directory) if repository_path != nil

    filename = artifact_id + '-'
    filename +=
            if version.end_with?("-SNAPSHOT") and repository_path != nil
              resolve_unique_version(version, File.join(directory, "maven-metadata.xml"))
            else
              version
            end
    filename += '-' + classifier if classifier != ''
    filename += '.' + packaging
    File.join(directory, filename)
  end

  def resolve_unique_version(version, metadata_file)
    begin
      doc = File.open(metadata_file) { |file| REXML::Document.new(file) }
      timestamp = doc.elements["metadata/versioning/snapshot/timestamp"].text
      build_number = doc.elements["metadata/versioning/snapshot/buildNumber"].text
      version.sub(/-SNAPSHOT$/, '') + "-#{timestamp}-#{build_number}"
    rescue
      # did not contain maven-metadata.xml or was not using timestamped snapshots
      version
    end
  end

  def simple_name
    artifact_id + '.' + packaging
  end
end
