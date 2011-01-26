class ServerMonitor < Screwcap::Base
  def initialize(options = {}, &block)
    super
    self.__name = options.delete(:name)
    self.__options = options
    self.__options[:servers] = [self.__options[:servers]] unless self.__options[:servers].class == Array

    self.__options[:alert] = [self.__options[:alert]] if self.__options[:alert] and self.__options[:alert].class != Array
    self.__commands = []
    validate
    yield if block_given?
  end

  def run(cmd, options = {})
    self.__commands << options.merge(:command => cmd)
  end

  private 

  def validate
    self.__options[:servers].each do |server|
      unless self.__options[:all_servers].map(&:name).include?(server)
        raise ArgumentError, "Cannot find server named :#{server} to monitor."
      end
    end
    if self.__options[:alert]
      consider = self.__options[:sysops].map {|s| s[:name] }
      consider += self.__options[:groups].map {|g| g[:name] } if self.__options[:groups]
      consider.flatten!
      self.__options[:alert].each do |alert|
        unless consider.include?(alert)
          raise ArgumentError, "Cannot find sysop or group named :#{alert} to alert."
        end
      end
    end
  end
end

class TaskManager
  def monitor(servers, options = {}, &block)
    self.__monitors ||= []
    self.__monitors << ServerMonitor.new(options.merge(:all_servers => self.__servers, 
                                                       :servers => servers,
                                                       :sysops => self.__sysops,
                                                       :groups => self.__groups
                                                      ))
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
