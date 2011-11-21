require 'fileutils'
require 'socket'

module ZK
  class ZookeeperServer

    ZKHOME = File.dirname(__FILE__) + "/zookeeper-3.3.3"

    def self.running?
      return false if !File.exist? pid_file

      pid = `cat #{pid_file}`
      return false if $?.exitstatus != 0

      `ps ax | grep #{pid}`
      $?.exitstatus == 0
    end

    def self.start(config_dir=nil, background=true)
      set_log_level

      export_zoo_cfg = ""
      export_zoo_cfg = "export ZOOCFGDIR='#{config_dir}' && " if !config_dir.nil?

      FileUtils.remove_dir(data_dir, true)
      FileUtils.mkdir_p(data_dir)

      if background
        thread = Thread.new do
          `#{export_zoo_cfg} cd #{ZKHOME} && ./bin/zkServer.sh start`
        end
        sleep 1
      else
        `#{export_zoo_cfg} cd #{ZKHOME} && ./bin/zkServer.sh start`
      end

      nil
    end

    def self.wait_til_started
      while !running?
        sleep 1
      end
    end

    def self.wait_til_stopped
      while running?
        sleep 1
      end
    end

    def self.stop(config_dir=nil)
      export_zoo_cfg = ""
      export_zoo_cfg = "export ZOOCFGDIR='#{config_dir}' && " if !config_dir.nil?

      `#{export_zoo_cfg} cd #{ZKHOME} && ./bin/zkServer.sh stop`
      # FileUtils.rm pid_file if File.exist? pid_file
    end

    def self.status(host="localhost", port=2181)
      retryable(:tries => 3, :on => Exception) do
        read_stat(host, port)
      end
    end

    # =======
    private
    # =======

    def self.data_dir
      "#{ZKHOME}/data/localhost"
    end

    def self.pid_file
      data_dir + "/zookeeper_server.pid"
    end

    #
    # Read Zookeeper status from socket
    #
    def self.read_stat(host, port)
      stat = {}
      s = TCPSocket.open(host, port)
      s.puts("stat")

      while line = s.gets   # Read lines from the socket
        if line =~ /^\S/ then 
          k,v = line.split(":")
          k.downcase!
          k.strip!
          v.strip!
          stat[k] = v
        end
      end
      s.close
      stat
    end

    #
    # Retry on exception
    #
    def self.retryable(options = {}, &block)
      opts = { :tries => 1, :on => Exception }.merge(options)

      retry_exception, retries = opts[:on], opts[:tries]

      begin
        return yield
      rescue retry_exception
        retry if (retries -= 1) > 0
      end

      yield
    end

    def self.set_log_level
      require ZKHOME + '/lib/log4j-1.2.15.jar'
      Java::org.apache.log4j.Logger.getRootLogger().set_level(Java::org.apache.log4j.Level::OFF)
    end

  end
end
