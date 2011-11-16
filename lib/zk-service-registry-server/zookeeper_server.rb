require 'fileutils'

module ZK
  class ZookeeperServer

    ZKHOME = File.dirname(__FILE__) + "/zookeeper-3.3.3"

    def self.running?
      pid = `cat #{@@data_dir}/zookeeper_server.pid`
      `ps ax | grep #{pid}`
      $?.exitstatus == 0
    end

    def self.start(background=true)
      set_log_level
      @@data_dir = "#{ZKHOME}/data/localhost"
      FileUtils.remove_dir(@@data_dir, true)
      FileUtils.mkdir_p(@@data_dir)
      if background
        thread = Thread.new do
          `cd #{ZKHOME} && ./bin/zkServer.sh start`
        end
      else
        `cd #{ZKHOME} && ./bin/zkServer.sh start`
      end
    end

    def self.wait_til_started
      while !running?
        sleep 1
      end
      # make sure zookeeper is really ready
      sleep 2
    end

    def self.wait_til_stopped
      while running?
        sleep 1
      end
    end

    def self.stop
      `cd #{ZKHOME} && ./bin/zkServer.sh stop`
      # FileUtils.remove_dir(@@data_dir, true)
    end

    def self.status
      `cd #{ZKHOME} && ./bin/zkServer.sh status`
    end

    def self.set_log_level
      require ZKHOME + '/lib/log4j-1.2.15.jar'
      Java::org.apache.log4j.Logger.getRootLogger().set_level(Java::org.apache.log4j.Level::OFF)
    end

  end
end
