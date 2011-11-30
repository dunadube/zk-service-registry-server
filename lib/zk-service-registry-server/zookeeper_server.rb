require 'fileutils'
require 'socket'

module ZK
  module Utils

    def write_file(fn, c)
      if c.kind_of? Hash
        File.open(fn, 'w') do |f|
          c.each_pair do |k, v|

            f.puts("#{k}=#{v}") 
          end
        end 
      else
        File.open(fn, 'w') {|f| f.write(c) }
      end
    end

    def read_file(fn)
      begin
        file = File.open(fn, "r")
        res = file.read
      rescue
        file.close if file
        res
      end
    end

    def kill_if_running(pidfile, opts = {})
      return if !File.exists?(pidfile)

      pid = read_pid(pidfile)
      File.delete(pidfile)

      return if !alive?(pid)

      Process.kill(15, pid)

      (1..5).each do
        return if !alive?(pid)
        sleep 1
      end
      Process.kill(9, pid)
    end

    def alive?(pid)
      begin
        Process.kill(0, pid)
        true
      rescue Errno::ESRCH
        false
      end
    end

    def read_pid(pidfile)
      raise ArgumentError.new("Pidfile #{pidfile} does not exist") if !File.exists?(pidfile)

      read_file(pidfile).strip.to_i
    end

  end

  class ZookeeperServer
    extend Utils

    # zookeeper home directory
    ZKHOME = File.expand_path(File.dirname(__FILE__)) + "/zookeeper-3.3.3"
    # zookeeper pid file
    ZKPidFileName = "zookeeper.pid"

    # 
    # Check if the zookeeper process is running
    #
    def self.running?(opts = {})
      pid_dir = "#{ZKHOME}/data/localhost"
      pid_dir = opts[:pid_dir] if opts[:pid_dir]
      pid_file = pid_dir + "/#{ZKPidFileName}"

      return false if !File.exists? pid_file

      alive?(read_pid(pid_file))
    end

    #
    # Start the Zookeeper Service and create a pid file if successful
    #
    # # Parameters:
    # - cfg: Zookeeper configuration as hash. The contents of the hash 
    #   will be written to file (zoo.cfg by default). See
    #   http://zookeeper.apache.org/doc/r3.3.3/zookeeperAdmin.html for details.
    #   NOTE: By default the pid file will be written to the data directory.
    # - opts: additional options if you want to change log (:log_dir) or config 
    #   (:conf_dir) directories . NOTE: Please use ABSOLUTE paths
    #   opts also holds the server id (:myid) when running zookeeper in an ensemble
    #   configuration.
    #
    # # Returns: 
    #   the pid of the Zookeeper process if successful
    #
    def self.start(cfg = {}, opts = {})
      cfg = {:tickTime => 2000, :clientPort => 2181}.merge!(cfg)
      opts = {:wait_start => true}.merge!(opts)

      # set the parameters
      # the data directory goes into the zoo.cfg file
      data_dir      = cfg[:dataDir] || "#{ZKHOME}/data/localhost"
      cfg[:dataDir] = data_dir
      FileUtils.mkdir_p(data_dir)

      # directories
      log_dir       = opts[:log_dir] || "#{ZKHOME}"
      zoocfgdir     = opts[:conf_dir] || "#{ZKHOME}/conf"
      zoocfg        = "zoo.cfg"
      zoocfgpath    = "#{zoocfgdir}/#{zoocfg}"

      opts[:pid_dir] = data_dir if !opts[:pid_dir]
      FileUtils.mkdir_p opts[:pid_dir]
      pid_file      = "#{opts[:pid_dir]}/" + ZKPidFileName

      # JAVA stuff
      root_logger   = "INFO,CONSOLE"
      jars          = Dir["#{ZKHOME}/lib/*.jar", "#{ZKHOME}/*.jar"].join(":")
      classpath     = "#{zoocfgdir}:#{jars}"
      zoomain       = "org.apache.zookeeper.server.quorum.QuorumPeerMain"
      jvmflags      = ""

      # build the java command line
      cmd ="java  \'-Dzookeeper.log.dir=#{log_dir}\' \'-Dzookeeper.root.logger=#{root_logger}\' -cp \'#{classpath}\' #{jvmflags} #{zoomain} #{zoocfgpath}"  

      # if there is a zookeeper process still running 
      # then kill it now
      kill_if_running(pid_file)

      # write the zookeeper config file
      write_file(zoocfgpath, cfg)

      # if running in an ensemble then
      # write the myid file to the data directory
      if opts[:myid] then
        raise ArgumentError.new("You must include initLimit in cfg when running an ensemble") if !cfg.include? :initLimit
        raise ArgumentError.new("You must include syncLimit in cfg when running an ensemble") if !cfg.include? :syncLimit
        write_file(data_dir + "/myid", opts[:myid]) 
      end

      # run the command
      io = IO.popen(cmd, "r")
      write_file(pid_file, io.pid)

      # wait until we can make a connection to zookeeper
      if opts[:wait_start] == true
        stat = status("localhost", cfg[:clientPort])
      end

      # return the pid
      io.pid 
    end

    #
    # Stop the process using the pid from the pidfile
    # 
    # Parameters:
    # - opts is a hash of options. Use :dataDir to specify the location
    #   of the pid file if you used a different location on startup.
    #   NOTE: Use ABSOLUTE paths
    #
    def self.stop(opts = {})
      pid_dir = "#{ZKHOME}/data/localhost"
      pid_dir = opts[:pid_dir] if opts[:pid_dir]

      kill_if_running(pid_dir + "/#{ZKPidFileName}", :force => true)
    end

    def self.wait_til_started
      while status == {} 
      end
    end

    def self.status(host="localhost", port=2181)
      retryable(:tries => 5, :on => Exception) do
        read_stat(host, port)
      end
    end

    # =======
    private
    # =======

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
          v.strip! if !v.nil?
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
        sleep 1
        retry if (retries -= 1) > 0
      end

      yield
    end

  end
end
