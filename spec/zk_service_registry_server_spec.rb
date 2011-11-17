require File.join(File.dirname(__FILE__), %w[spec_helper])
require File.dirname(__FILE__) + "/../lib/zk-service-registry-server.rb"

describe ZK::ZookeeperServer do
  context "when the zookeeper service is running" do
    before  do
      ZK::ZookeeperServer.start
      ZK::ZookeeperServer.wait_til_started
    end

    after  do
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

  context "when i want to use a different configuration (port)" do

    it "should be possible to specify a config file on start" do
      config_file = File.dirname(__FILE__) + "/../lib/zk-service-registry-server/zookeeper-3.3.3/conf_alt"

      ZK::ZookeeperServer.start(config_file)
      ZK::ZookeeperServer.wait_til_started

      ZK::ZookeeperServer.status("localhost", 2182)["mode"].should eql("standalone")

      ZK::ZookeeperServer.stop
      ZK::ZookeeperServer.wait_til_stopped
      ZK::ZookeeperServer.running?.should eql(false)
    end
  end
end
