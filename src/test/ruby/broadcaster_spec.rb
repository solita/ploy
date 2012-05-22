require_relative '../../main/ruby/broadcaster'
require_relative 'test_helpers'

describe Broadcaster do

  it "forwards all methods calls to all targets" do
    target1 = double('target1')
    target2 = double('target2')
    broadcaster = Broadcaster.new(target1, target2)

    target1.should_receive(:some_method).with('arg1', 'arg2')
    target2.should_receive(:some_method).with('arg1', 'arg2')

    broadcaster.some_method('arg1', 'arg2')
  end
end
