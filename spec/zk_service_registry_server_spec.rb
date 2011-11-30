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
      stat = ZK::ZookeeperServer.status
      stat["mode"].should eql("standalone")
    end
  end

  context "when i want to run Zookeeper in an ensemble configuration" do

    it "should be possible to specify an ensemble configuration" do
      cfg             = {}
      cfg[:dataDir]   = File.expand_path(File.dirname(__FILE__)) + "/zoo_ensemble_cfg/data"
      cfg[:initLimit] = 5
      cfg[:syncLimit] = 2
      cfg["server.1"] = "zoo1:2888:3888"
      cfg["server.2"] = "zoo2:2888:3888"
      cfg["server.3"] = "zoo3:2888:3888"

      opts            = { :myid => "1" }
      opts[:conf_dir] = File.expand_path(File.dirname(__FILE__)) + "/zoo_ensemble_cfg"
      opts[:pid_dir]  = File.expand_path(File.dirname(__FILE__)) + "/zoo_pid"

      ZK::ZookeeperServer.start(cfg, opts)
      ZK::ZookeeperServer.status
      File.exists?( opts[:pid_dir] + "/zookeeper.pid" ).should eql(true)
      ZK::ZookeeperServer.stop(opts)
      ZK::ZookeeperServer.running?.should eql(false)
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
