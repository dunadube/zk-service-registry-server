require File.join(File.dirname(__FILE__), %w[spec_helper])
require File.dirname(__FILE__) + "/../lib/zk-service-registry-server.rb"

describe ZK::ZookeeperServer do
  context "when the zookeeper service is running" do
    before  do
      ZK::ZookeeperServer.start
    end

    after  do
      ZK::ZookeeperServer.stop
      ZK::ZookeeperServer.running?.should eql(false)
    end

    it "makes sure the Zookeeper Server has been started" do
      ZK::ZookeeperServer.running?.should eql(true)
    end

    it "makes sure to get a connection to the Zookeeper Server" do
      ZK::ZookeeperServer.status["mode"].should eql("standalone")
    end
  end

  context "when i want to run Zookeeper in an ensemble configuration" do
    it "should be possible to give it a custom configuration" do
    end
  end

  context "when i want to use a different configuration (port)" do

    it "should be possible to specify a config file on start" do
      cfg              = {}
      cfg[:clientPort] = 2182
      opts             = {}
      opts[:conf_dir]  = File.expand_path(File.dirname(__FILE__)) + "/zoo_alternative_cfg"

      ZK::ZookeeperServer.start(cfg, opts)

      stat = ZK::ZookeeperServer.status("localhost", 2182)
      stat["mode"].should eql("standalone")

      ZK::ZookeeperServer.stop
      ZK::ZookeeperServer.running?.should eql(false)
    end
  end
end
