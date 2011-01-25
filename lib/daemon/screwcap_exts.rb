class ServerMonitor < Screwcap::Base
  def initialize(options = {}, &block)
    super
    self.__name = options.delete(:name)
    self.__options = options
    self.__commands = []
    self.__servers = []
    yield if block_given?
  end

  def run(cmd, options = {})
    self.__commands << options.merge(:command => cmd)
  end
end

class TaskManager
  def monitor(servers, options = {}, &block)
    self.__monitors ||= []
    self.__monitors << ServerMonitor.new(options.merge(:servers => servers))
  end

  def checks_for(server, options = {}, &block)
    t = Task.new(options.merge({:name => "task", :server => server}), &block)
    t.clone_from(self)
    t.validate(self.__servers) unless options[:local] == true
    self.__tasks << t
  end

  def twilio(sid, token)
    self.__twilio_sid = sid
    self.__twilio_token =  token
  end

  def sysop(name, hsh)
    self.__sysops ||= []
    self.__sysops << hsh.merge(:name => name)
  end

  def group(name, members)
    self.__groups ||= []
    self.__groups << {:name => name, :members => members}
  end

  def check(name, cmd)
    self.__checks ||= []
    self.__checks << {:name => name, :command => cmd}
  end
end
