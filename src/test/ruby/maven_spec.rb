require_relative '../../main/ruby/maven'
require_relative 'test_helpers'

describe MavenArtifact do

  it "decomposes an artifact string to its elements" do
    artifact = MavenArtifact.new("com.example.group-id:the-artifact:4.2:zip:the-classifier")

    artifact.group_id.should == "com.example.group-id"
    artifact.artifact_id.should == "the-artifact"
    artifact.version.should == "4.2"
    artifact.packaging.should == "zip"
    artifact.classifier.should == "the-classifier"
  end

  it "classifier is optional, defaults to empty string" do
    artifact = MavenArtifact.new("com.example.group-id:the-artifact:4.2:jar")

    artifact.classifier.should == ""
  end

  it "packaging is optional, defaults to 'jar'" do
    artifact = MavenArtifact.new("com.example.group-id:the-artifact:4.2")

    artifact.packaging.should == "jar"
  end

  it "finds artifact from local repository, with classifier" do
    artifact = MavenArtifact.new("com.example.group-id:the-artifact:4.2:zip:the-classifier")

    artifact.path.should == "com/example/group-id/the-artifact/4.2/the-artifact-4.2-the-classifier.zip"
  end

  it "finds artifact from local repository, without classifier" do
    artifact = MavenArtifact.new("com.example.group-id:the-artifact:4.2:jar")

    artifact.path.should == "com/example/group-id/the-artifact/4.2/the-artifact-4.2.jar"
  end

  it "returns artifact's full path if the repository's path is provided" do
    artifact = MavenArtifact.new("com.example.group-id:the-artifact:4.2:jar")
    repository = "/home/johndoe/.m2/repository"

    artifact.path(repository).should == "/home/johndoe/.m2/repository/com/example/group-id/the-artifact/4.2/the-artifact-4.2.jar"
  end

  it "provides a simple file name without version number" do
    artifact = MavenArtifact.new("com.example.group-id:the-artifact:4.2:jar")

    artifact.simple_name.should == "the-artifact.jar"
  end
end
