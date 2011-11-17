require File.join(File.dirname(__FILE__), %w[spec_helper])
require File.dirname(__FILE__) + "/../lib/zk-service-registry-server.rb"

describe ZK::ZookeeperServer do
  before :all do
    ZK::ZookeeperServer.start
    ZK::ZookeeperServer.wait_til_started
  end

  after :all do
    ZK::ZookeeperServer.stop
    ZK::ZookeeperServer.wait_til_stopped
    ZK::ZookeeperServer.running?.should eql(false)
  end

  it "makes sure the Zookeeper Server has been started" do
    ZK::ZookeeperServer.running?.should eql(true)
  end

  it "makes sure to get a connection to the Zookeeper Server" do
    ZK::ZookeeperServer.status["mode"].should eql("standalone")
  end
end
